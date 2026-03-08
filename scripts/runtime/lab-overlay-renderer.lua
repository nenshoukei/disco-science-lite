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
local map_position_tuple = Utils.map_position_tuple
local get_entity_rect = Utils.get_entity_rect
local MOD_NAME = consts.MOD_NAME
local STATUS_WORKING = defines.entity_status.working
local STATUS_LOW_POWER = defines.entity_status.low_power

local PV_VALID = PlayerViewTracker.PV_VALID
local PV_SURFACE = PlayerViewTracker.PV_SURFACE
local PV_LEFT = PlayerViewTracker.PV_LEFT
local PV_TOP = PlayerViewTracker.PV_TOP
local PV_RIGHT = PlayerViewTracker.PV_RIGHT
local PV_BOTTOM = PlayerViewTracker.PV_BOTTOM

--- @class LabOverlay
--- @field [1] LuaEntity        Lab entity. (OV_ENTITY)
--- @field [2] LuaRenderObject  Render object for the overlay. (OV_ANIMATION)
--- @field [3] MapPositionTuple Position of the entity. (OV_POSITION)
--- @field [4] MapPositionRect  Rectangle boundaries of the entity. (OV_RECT)
--- @field [5] boolean          Last known visible state of the animation (cached, avoids repeated C bridge reads). (OV_VISIBLE)
--- @field [6] number           Unit number of the lab entity (required by ChunkMap for swap-and-pop removal). (OV_UNIT_NUM)

-- LabOverlay field indices
local OV_ENTITY = 1    -- LuaEntity
local OV_ANIMATION = 2 -- LuaRenderObject
local OV_POSITION = 3  -- MapPositionTuple
local OV_RECT = 4      -- MapPositionRect
local OV_VISIBLE = 5   -- boolean (cached visible state)
local OV_UNIT_NUM = 6  -- number (unit_number)

--- Constructor
---
--- @param color_registry ColorRegistry
--- @param target_lab_registry TargetLabRegistry
--- @return LabOverlayRenderer
function LabOverlayRenderer.new(color_registry, target_lab_registry)
  --- @class LabOverlayRenderer
  local self = {
    color_registry = color_registry,
    target_lab_registry = target_lab_registry,

    --- Overlays for lab entities. Key is LuaEntity unit_number.
    --- @type table<number, LabOverlay>
    overlays = {},

    --- Spatial map for efficient view-range iteration.
    --- @type ChunkMap
    chunk_map = ChunkMap.new(),

    --- Tracks the single connected player's view and position.
    --- @type PlayerViewTracker
    player_tracker = PlayerViewTracker.new(),

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

  local target_lab = self.target_lab_registry:get(lab.name)
  if not target_lab then return nil end

  local animation = draw_animation({
    animation = target_lab.animation,
    surface = lab.surface,
    target = lab,
    x_scale = target_lab.scale,
    y_scale = target_lab.scale,
    render_layer = "higher-object-under",
    visible = false,
    animation_offset = settings.global[consts.RANDOM_FLICKER_NAME].value and random() * 300 or 0,
  })

  --- @type LabOverlay
  local new_overlay = {
    lab,                              -- [OV_ENTITY]   LuaEntity
    animation,                        -- [OV_ANIMATION] LuaRenderObject
    map_position_tuple(lab.position), -- [OV_POSITION]  MapPositionTuple
    get_entity_rect(lab),             -- [OV_RECT]      MapPositionRect
    false,                            -- [OV_VISIBLE]   Cached visible state (matches animation's initial visible=false)
    lab_unit_number,                  -- [OV_UNIT_NUM]  Required by ChunkMap for swap-and-pop removal
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
  rendering_clear(MOD_NAME)
  self.overlays = {}
  self.chunk_map = ChunkMap.new()

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
function LabOverlayRenderer:update_overlay_states()
  local player_tracker = self.player_tracker
  local view = player_tracker.view
  if not view[PV_VALID] then return end

  -- player_tracker.force is always set when view[PV_VALID] is true.
  local player_force = player_tracker.force --[[@as LuaForce]]
  local current_research = player_force.current_research
  if current_research ~= self.current_research then
    self.current_research = current_research
    self.current_research_colors = current_research and self.color_registry:get_colors_for_research(current_research)
  end
  local current_research_colors = self.current_research_colors

  local surface_chunks = self.chunk_map.data[view[PV_SURFACE]]
  if not surface_chunks then return end

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
          end
        end
      end
    end
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

  local chunk_map_data = self.chunk_map.data
  local player_tracker = self.player_tracker
  local view = player_tracker.view
  local player_position = player_tracker.position

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
    local current_research_colors = self.current_research_colors
    if not current_research_colors then return end

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

    -- Update overlays in the chunk range visible to the player.
    local surface_chunks = chunk_map_data[view[PV_SURFACE]]
    if surface_chunks then
      local chunk_left = view[PV_LEFT]
      local chunk_top = view[PV_TOP]
      local chunk_right = view[PV_RIGHT]
      local chunk_bottom = view[PV_BOTTOM]

      -- We do this for performance
      local player_position = player_position         --- @diagnostic disable-line: redefined-local
      local phase = phase                             --- @diagnostic disable-line: redefined-local
      local color_function = color_function           --- @diagnostic disable-line: redefined-local
      local color = color                             --- @diagnostic disable-line: redefined-local
      local lab_update_offset = lab_update_offset     --- @diagnostic disable-line: redefined-local
      local LAB_UPDATE_INTERVAL = lab_update_interval --- @diagnostic disable-line: redefined-local
      local OV_VISIBLE = OV_VISIBLE                   --- @diagnostic disable-line: redefined-local
      local OV_ANIMATION = OV_ANIMATION               --- @diagnostic disable-line: redefined-local
      local OV_POSITION = OV_POSITION                 --- @diagnostic disable-line: redefined-local

      for cx = chunk_left, chunk_right do
        local col = surface_chunks[cx]
        if col then
          for cy = chunk_top, chunk_bottom do
            local chunk = col[cy]
            if chunk then
              for i = lab_update_offset, #chunk, LAB_UPDATE_INTERVAL do
                local overlay = chunk[i]
                -- overlay[OV_VISIBLE] is updated by update_overlay_states() every 30 ticks.
                if overlay[OV_VISIBLE] then
                  local animation = overlay[OV_ANIMATION]
                  local entity_position = overlay[OV_POSITION]
                  color_function(color, phase, current_research_colors, player_position, entity_position)
                  animation.color = color
                end
              end
            end
          end
        end
      end
    end
  end
end

return LabOverlayRenderer
