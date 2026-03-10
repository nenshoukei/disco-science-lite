local consts = require("scripts.shared.consts")
local Utils = require("scripts.shared.utils")
local ColorFunctions = require("scripts.runtime.color-functions")
local ChunkMap = require("scripts.runtime.chunk-map")
local PlayerViewTracker = require("scripts.runtime.player-view-tracker")

--- @class LabOverlayRenderer
local LabOverlayRenderer = {}
LabOverlayRenderer.__index = LabOverlayRenderer

local random = math.random
local rendering_clear = rendering.clear
local draw_animation = rendering.draw_animation
local position_to_chunk = Utils.position_to_chunk
local get_entity_rect = Utils.get_entity_rect
local STATUS_WORKING = defines.entity_status.working
local STATUS_LOW_POWER = defines.entity_status.low_power

local PV_VALID = PlayerViewTracker.PV_VALID
local PV_SURFACE = PlayerViewTracker.PV_SURFACE
local PV_LEFT = PlayerViewTracker.PV_LEFT
local PV_TOP = PlayerViewTracker.PV_TOP
local PV_RIGHT = PlayerViewTracker.PV_RIGHT
local PV_BOTTOM = PlayerViewTracker.PV_BOTTOM

--- @class (exact) LabOverlay
--- @field [1] LuaEntity        Lab entity. (OV_ENTITY)
--- @field [2] LuaRenderObject  Render object for the overlay. (OV_ANIMATION)
--- @field [3] number           X coordinate. (OV_X)
--- @field [4] number           Y coordinate. (OV_Y)
--- @field [5] MapPositionRect  Rectangle boundaries of the entity. (OV_RECT)
--- @field [6] boolean          Last known visible state of the animation (cached, avoids repeated C bridge reads). (OV_VISIBLE)
--- @field [7] number           Unit number of the lab entity (required by ChunkMap for swap-and-pop removal). (OV_UNIT_NUM)
--- @field [8] integer          Chunk X coordinate. (OV_CHUNK_X)
--- @field [9] integer          Chunk Y coordinate. (OV_CHUNK_Y)

-- LabOverlay field indices
local OV_ENTITY = 1
local OV_ANIMATION = 2
local OV_X = 3
local OV_Y = 4
local OV_RECT = 5
local OV_VISIBLE = 6
local OV_UNIT_NUM = 7
local OV_CHUNK_X = 8
local OV_CHUNK_Y = 9

--- Constructor
---
--- @param color_registry ColorRegistry
--- @param lab_registry LabRegistry
--- @return LabOverlayRenderer
function LabOverlayRenderer.new(color_registry, lab_registry)
  --- @class LabOverlayRenderer
  local self = {
    color_registry = color_registry,
    lab_registry = lab_registry,

    --- Overlays for lab entities. Key is LuaEntity unit_number.
    --- @type table<number, LabOverlay>
    overlays = {},

    --- Spatial map for efficient view-range iteration.
    --- @type ChunkMap
    chunk_map = ChunkMap.new(),

    --- Tracks the single connected player's view and position.
    --- @type PlayerViewTracker
    player_tracker = PlayerViewTracker.new(),

    --- Flattened list of lab overlays currently in the player's view. Update by update_overlay_states().
    --- @type LabOverlay[]
    visible_overlays = {},

    --- Current research being tracked. Updated by update_overlay_states().
    --- @type LuaTechnology|nil
    current_research = nil,

    --- Colors for the current research. Updated by update_overlay_states() when research changes.
    --- nil when no research is active or no player is connected.
    --- @type ColorTuple[]|nil
    current_research_colors = nil,
  }
  return setmetatable(self, LabOverlayRenderer)
end

--- Render an overlay for a lab entity.
---
--- If the overlay already exists and `force_render` is `false`, skip rendering and returns the existing overlay.
---
--- @param lab LuaEntity The lab entity.
--- @param force_render boolean? If `true`, it renders the overlay even if it already exists.
--- @return LabOverlay|nil # The rendered overlay. `nil` if the lab is not target.
function LabOverlayRenderer:render_overlay_for_lab(lab, force_render)
  if not lab.valid or lab.type ~= "lab" then return nil end

  local lab_unit_number = lab.unit_number
  if not lab_unit_number then return nil end

  local overlay = self.overlays[lab_unit_number]
  if overlay and not force_render then return overlay end

  -- Only create overlays for labs belonging to the player's force.
  -- force is nil in multiplayer (or before first player_tracker:update()), so skip all.
  local player_force = self.player_tracker.force
  if not player_force or lab.force_index ~= player_force.index then return nil end

  local overlay_settings = self.lab_registry:get_overlay_settings(lab.name)
  if not overlay_settings and not settings.startup[consts.FALLBACK_OVERLAY_ENABLED_NAME].value then
    return nil
  end

  --- @type LuaRenderObject
  local render_object
  if overlay_settings then
    render_object = draw_animation({
      animation = overlay_settings.animation,
      surface = lab.surface,
      target = lab,
      x_scale = overlay_settings.scale,
      y_scale = overlay_settings.scale,
      render_layer = "higher-object-under",
      visible = false,
      animation_offset = not settings.global[consts.UNISON_FLICKER_NAME].value and random() * 300 or 0,
    })
  else
    -- Fallback: use a generic glow animation for labs without a registered overlay sprite.
    -- Scale the overlay to fit the lab's tile size. The fallback sprite covers 2 tiles at scale=1.
    local prototype = lab.prototype
    local scale = math.max(prototype.tile_width, prototype.tile_height) / 2
    render_object = draw_animation({
      animation = consts.GENERAL_OVERLAY_ANIMATION_NAME,
      surface = lab.surface,
      target = lab,
      x_scale = scale,
      y_scale = scale,
      render_layer = "higher-object-under",
      visible = false,
      animation_offset = not settings.global[consts.UNISON_FLICKER_NAME].value and random() * 300 or 0,
    })
  end

  local lab_position = lab.position
  local lab_x, lab_y = lab_position.x or lab_position[1], lab_position.y or lab_position[2]
  local chunk_x, chunk_y = position_to_chunk(lab_x, lab_y)

  --- @type LabOverlay
  local new_overlay = {
    lab,                  -- [OV_ENTITY]
    render_object,        -- [OV_ANIMATION]
    lab_x,                -- [OV_X]
    lab_y,                -- [OV_Y]
    get_entity_rect(lab), -- [OV_RECT]
    false,                -- [OV_VISIBLE]
    lab_unit_number,      -- [OV_UNIT_NUM]
    chunk_x,              -- [OV_CHUNK_X]
    chunk_y,              -- [OV_CHUNK_Y]
  }

  self.overlays[lab_unit_number] = new_overlay
  self.chunk_map:insert(lab, new_overlay)

  -- Register the lab entity to be notified by `on_object_destroyed` when it is destroyed.
  script.register_on_object_destroyed(lab)

  return new_overlay
end

--- Render overlays for all lab entities.
---
--- The tick function returned by `get_tick_function()` should be refreshed afterwards.
function LabOverlayRenderer:render_overlays_for_all_labs()
  -- Update player tracker so render_overlay_for_lab can filter by the current player force.
  self.player_tracker:update(game.connected_players)

  -- Destroy all rendering objects and reset data structures.
  -- This is necessary because the force filter may exclude labs that were previously included
  -- (e.g. after on_player_changed_force), leaving stale entries with invalid animations.
  rendering_clear(consts.MOD_NAME)
  self.overlays = {}
  self.chunk_map = ChunkMap.new()
  self.visible_overlays = {}
  self.current_research = nil
  self.current_research_colors = nil

  local entity_filter = { type = "lab" }
  local render_overlay_for_lab = self.render_overlay_for_lab
  for _, surface in pairs(game.surfaces) do
    for _, lab in ipairs(surface.find_entities_filtered(entity_filter)) do
      render_overlay_for_lab(self, lab, true) -- Force re-render
    end
  end
end

--- Remove the overlay from the lab entity.
---
--- @param lab_unit_number number The unit_number of the removed lab entity.
function LabOverlayRenderer:remove_overlay_from_lab(lab_unit_number)
  if not lab_unit_number then return end

  local overlay = self.overlays[lab_unit_number]
  if not overlay then return end

  local animation = overlay[OV_ANIMATION]
  if animation.valid then
    animation.destroy()
  end

  self.chunk_map:remove(lab_unit_number)
  self.overlays[lab_unit_number] = nil

  -- Removing the overlay from the visible_overlays list is necessary to prevent
  -- a potential crash in the tick function if it tries to color a destroyed animation.
  -- This is O(N) but only happens when a lab is destroyed (rare).
  local visible_overlays = self.visible_overlays
  for i = 1, #visible_overlays do
    if visible_overlays[i] == overlay then
      table.remove(visible_overlays, i)
      break
    end
  end
end

--- Remove all overlays on the given surface.
---
--- Call this on `on_surface_deleted` or `on_surface_cleared`.
--- Destroys render objects if still valid (e.g. on surface clear), and cleans up Lua data structures.
---
--- @param surface_index number
function LabOverlayRenderer:remove_overlays_on_surface(surface_index)
  local surface_chunks = self.chunk_map.data[surface_index]
  if not surface_chunks then return end

  local overlays = self.overlays
  local entries = self.chunk_map.entries
  for _, col in pairs(surface_chunks) do
    for _, chunk in pairs(col) do
      for i = 1, #chunk do
        local overlay = chunk[i]
        local unit_number = overlay[OV_UNIT_NUM]
        local animation = overlay[OV_ANIMATION]
        if animation.valid then
          animation.destroy()
        end
        overlays[unit_number] = nil
        entries[unit_number] = nil
      end
    end
  end

  self.chunk_map.data[surface_index] = nil
end

--- Update the lab entity position for updating its overlay.
---
--- @param lab LuaEntity
function LabOverlayRenderer:update_lab_position(lab)
  local lab_unit_number = lab.unit_number
  if not lab_unit_number then return end

  local overlay = self.overlays[lab_unit_number]
  if not overlay then return end

  overlay[OV_RECT] = get_entity_rect(lab)

  local animation = overlay[OV_ANIMATION]
  if animation.surface.index == lab.surface_index then
    -- Same surface: update animation target and chunk map if chunk changed.
    animation.target = lab
    self.chunk_map:move(lab)
  else
    -- The entity is teleported to another surface!
    animation.destroy()
    self.chunk_map:remove(lab_unit_number)
    self.overlays[lab_unit_number] = nil
    self:render_overlay_for_lab(lab, true) -- Force re-render
  end
end

--- Update the players from `game.connected_players`.
---
--- Called by event handlers (position/zoom/surface changes).
function LabOverlayRenderer:update_players()
  self.player_tracker:update(game.connected_players)
end

--- Update overlay states for labs in the player's view.
---
--- Called periodically (not every tick) to avoid expensive C bridge calls on every tick:
---   - Tracks current research and updates current_research_colors when it changes.
---   - Checks entity.status and updates overlay[OV_VISIBLE] and animation.visible.
---   - Update self.visible_overlays for iterating lab overlays in the player's view.
function LabOverlayRenderer:update_overlay_states()
  local player_tracker = self.player_tracker
  local view = player_tracker.view
  if not view[PV_VALID] then return end

  -- player_tracker.force is always set when view[PV_VALID] is true.
  local player_force = player_tracker.force --[[@as LuaForce]]
  local current_research = player_force.current_research
  if current_research ~= self.current_research then
    self.current_research = current_research
    if current_research then
      local intensity = settings.global[consts.COLOR_INTENSITY_NAME].value * 0.01 --[[@as number]]
      self.current_research_colors = self.color_registry:get_colors_for_research(current_research, intensity)
    else
      self.current_research_colors = nil
    end
  end
  local current_research_colors = self.current_research_colors

  local surface_chunks = self.chunk_map.data[view[PV_SURFACE]]
  local visible_overlays = self.visible_overlays
  local count = 0

  if surface_chunks then
    local chunk_left = view[PV_LEFT]
    local chunk_top = view[PV_TOP]
    local chunk_right = view[PV_RIGHT]
    local chunk_bottom = view[PV_BOTTOM]

    for cx = chunk_left, chunk_right do
      local col = surface_chunks[cx]
      if col then
        for cy = chunk_top, chunk_bottom do
          local chunk = col[cy]
          if chunk then
            for i = 1, #chunk do
              local overlay = chunk[i]
              local status = overlay[OV_ENTITY].status
              local is_visible = (
                (status == STATUS_WORKING or status == STATUS_LOW_POWER) and
                current_research_colors ~= nil
              )
              if overlay[OV_VISIBLE] ~= is_visible then
                overlay[OV_VISIBLE] = is_visible
                overlay[OV_ANIMATION].visible = is_visible
              end

              if is_visible then
                count = count + 1
                visible_overlays[count] = overlay
              end
            end
          end
        end
      end
    end
  end

  -- Clear trailing lab overlay references from the table to prevent memory leaks and GC issues.
  -- Setting elements to nil ensures that #visible_overlays accurately reflects the current count.
  for i = count + 1, #visible_overlays do
    if visible_overlays[i] == nil then break end
    visible_overlays[i] = nil
  end
end

--- Get a tick function to be called by on_tick event.
---
--- The function updates overlays in the chunk range visible to the player.
---
--- @return fun()
function LabOverlayRenderer:get_tick_function()
  -- Because a tick function is critical for UPS (Updates Per Second), we should optimize it very tightly.
  --
  -- For optimization, as much as possible we should:
  -- * Avoid access to the same key on a table multiple times.
  -- * Avoid access to a table by using string keys. Use array indices instead.
  -- * Avoid access to the same outer-scope variable (upvalue) multiple times.
  -- * Avoid function calls. Make it inline.
  -- * Avoid creating a new object.
  -- * Avoid access to native objects provided by Factorio. C bridge call is expensive.

  local global_settings = settings.global
  local color_pattern_duration = global_settings[consts.COLOR_PATTERN_DURATION_NAME].value --[[@as integer]]
  local lab_update_interval = global_settings[consts.LAB_UPDATE_INTERVAL_NAME].value --[[@as integer]]

  local player_tracker = self.player_tracker
  local view = player_tracker.view
  local player_position = player_tracker.position
  local visible_overlays = self.visible_overlays

  -- `phase` is a continuously drifting value passed to the color function.
  -- It drives animation by shifting the color cycle position over time.
  local phase = 0
  local phase_speed = ((random() * 5 + 3.5) % 6) - 3 -- [-3.0, -0.5) or [0.5, 3.0)
  local color_function, color_function_index = ColorFunctions.choose_random()
  local color_pattern_counter = 0
  local color = { 0, 0, 0 }
  local lab_update_offset = 1

  return function ()
    -- Return early when no player is active (disconnected or in chart mode).
    -- `view` is captured once at closure creation; it is mutated in-place by player_tracker:update().
    if not view[PV_VALID] then return end

    -- Return early when no research is active. All overlays are invisible, nothing to update.
    local colors = self.current_research_colors
    if not colors then return end
    local n_colors = #colors

    phase = phase + phase_speed

    -- Switch color function periodically. Also update phase_speed.
    color_pattern_counter = color_pattern_counter + 1
    if color_pattern_counter >= color_pattern_duration then
      color_pattern_counter = 0
      color_function, color_function_index = ColorFunctions.choose_random(color_function_index)
      phase_speed = ((random() * 5 + 3.5) % 6) - 3
    end

    lab_update_offset = lab_update_offset + 1
    if lab_update_offset > lab_update_interval then lab_update_offset = 1 end

    local player_x, player_y = player_position[1], player_position[2]

    -- Bind upvalues to local variables for performance
    -- luacheck: push ignore
    local visible_overlays = visible_overlays       --- @diagnostic disable-line: redefined-local
    local phase = phase                             --- @diagnostic disable-line: redefined-local
    local color_function = color_function           --- @diagnostic disable-line: redefined-local
    local color = color                             --- @diagnostic disable-line: redefined-local
    local lab_update_offset = lab_update_offset     --- @diagnostic disable-line: redefined-local
    local lab_update_interval = lab_update_interval --- @diagnostic disable-line: redefined-local
    local OV_ANIMATION = OV_ANIMATION               --- @diagnostic disable-line: redefined-local
    local OV_X = OV_X                               --- @diagnostic disable-line: redefined-local
    local OV_Y = OV_Y                               --- @diagnostic disable-line: redefined-local
    local OV_CHUNK_X = OV_CHUNK_X                   --- @diagnostic disable-line: redefined-local
    local OV_CHUNK_Y = OV_CHUNK_Y                   --- @diagnostic disable-line: redefined-local
    -- luacheck: pop

    -- Update colors of the visible overlays using stride iteration
    for i = lab_update_offset, #visible_overlays, lab_update_interval do
      local overlay = visible_overlays[i]
      color_function(
        color, phase, colors, n_colors, player_x, player_y, overlay[OV_X], overlay[OV_Y],
        overlay[OV_CHUNK_X], overlay[OV_CHUNK_Y]
      )
      overlay[OV_ANIMATION].color = color
    end
  end
end

return LabOverlayRenderer
