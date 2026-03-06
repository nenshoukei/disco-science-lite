local consts = require("scripts.shared.consts")
local config_target_labs = require("scripts.shared.config.target-labs")
local Utils = require("scripts.shared.utils")
local ColorFunctions = require("scripts.runtime.color-functions")
local ChunkMap = require("scripts.runtime.chunk-map")

--- @class LabOverlayRenderer
local LabOverlayRenderer = {}
LabOverlayRenderer.__index = LabOverlayRenderer

if script then
  script.register_metatable("LabOverlayRenderer", LabOverlayRenderer)
end

local ceil = math.ceil
local rendering_clear = rendering.clear
local draw_animation = rendering.draw_animation
local map_position_tuple = Utils.map_position_tuple
local get_entity_rect = Utils.get_entity_rect
local rect_to_chunk_range = ChunkMap.rect_to_chunk_range
local MOD_NAME = consts.MOD_NAME
local LAB_OVERLAY_ANIMATION_NAME = consts.LAB_OVERLAY_ANIMATION_NAME
local RENDER_MODE_CHART = defines.render_mode.chart
local STATUS_WORKING = defines.entity_status.working
local STATUS_LOW_POWER = defines.entity_status.low_power
local VIEW_RECT_MARGIN = 6 -- tiles

--- @class LabOverlay
--- @field [1] LuaEntity Lab entity.
--- @field [2] LuaRenderObject Render object for the overlay.
--- @field [3] MapPositionTuple Position of the entity.
--- @field [4] MapPositionRect Rectangle boundaries of the entity.

--- The chunk range visible to a single player.
--- @class PlayerView
--- @field [1] number Surface index.
--- @field [2] number Chunk left boundary.
--- @field [3] number Chunk top boundary.
--- @field [4] number Chunk right boundary.
--- @field [5] number Chunk bottom boundary.

--- Constructor
---
--- @param color_registry ColorRegistry
--- @return LabOverlayRenderer
function LabOverlayRenderer.new(color_registry)
  --- @class LabOverlayRenderer
  local self = {
    color_registry = color_registry,

    --- Dictionary of target labs. Key is LabPrototype name.
    target_labs = table.deepcopy(config_target_labs),

    --- Overlays for lab entities. Key is LuaEntity unit_number.
    --- @type table<number, LabOverlay>
    overlays = {},

    --- Spatial map for efficient view-range iteration.
    --- @type ChunkMap<LabOverlay>
    chunk_map = ChunkMap.new(),

    --- Chunk ranges visible to each connected player.
    --- Empty when no player is active (e.g. all in chart mode).
    --- @type PlayerView[]
    player_views = {},

    --- Player's position. Used by the color function.
    --- Updated to the first active player's position.
    --- @type MapPositionTuple
    player_position = { 0, 0 },

    --- Player's force. Used for research tracking.
    --- Updated to the first active player's force.
    --- @type LuaForce|nil
    player_force = nil,
  }
  return setmetatable(self, LabOverlayRenderer)
end

--- Add a new target lab type.
---
--- @param lab_name string LabPrototype name.
--- @param target_lab TargetLab Settings for the lab.
function LabOverlayRenderer:add_target_lab(lab_name, target_lab)
  self.target_labs[lab_name] = target_lab
end

--- Set scale of the target lab.
---
--- If the given lab is not a target, it will registers the lab as a target with the default overlay.
---
--- @param lab_name string LabPrototype name.
--- @param scale integer Scale of the lab. (Default scale is `1`)
function LabOverlayRenderer:set_lab_scale(lab_name, scale)
  local target_lab = self.target_labs[lab_name]
  if target_lab then
    target_lab.scale = scale
  else
    -- Automatically creates a TargetLab with the default overlay.
    self.target_labs[lab_name] = {
      animation = LAB_OVERLAY_ANIMATION_NAME,
      scale = scale,
    }
  end
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

  local target_lab = self.target_labs[lab.name]
  if not target_lab then return nil end

  local animation = draw_animation({
    animation = target_lab.animation,
    surface = lab.surface,
    target = lab,
    x_scale = target_lab.scale,
    y_scale = target_lab.scale,
    render_layer = "higher-object-under",
    visible = false,
  })

  local new_overlay = {
    lab,
    animation,
    map_position_tuple(lab.position),
    get_entity_rect(lab),
  }

  self.overlays[lab_unit_number] = new_overlay
  self.chunk_map:insert(lab, new_overlay)

  -- Register the lab entity to be notified by `on_object_destroyed` when it is destroyed.
  script.register_on_object_destroyed(lab)

  return new_overlay
end

--- Render overlays for all lab entities.
function LabOverlayRenderer:render_overlays_for_all_labs()
  -- Destroy all rendering objects by this mod.
  rendering_clear(MOD_NAME)

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
--- @param lab LuaEntity
function LabOverlayRenderer:remove_overlay_from_lab(lab)
  local lab_unit_number = lab.unit_number
  if not lab_unit_number then return end

  local overlay = self.overlays[lab_unit_number]
  if not overlay then return end

  local animation = overlay[2]
  if animation.valid then
    animation.destroy()
  end

  self.chunk_map:remove(lab_unit_number)
  self.overlays[lab_unit_number] = nil
end

--- Update the lab entity position for updating its overlay.
---
--- @param lab LuaEntity
function LabOverlayRenderer:update_lab_position(lab)
  local lab_unit_number = lab.unit_number
  if not lab_unit_number then return end

  local overlay = self.overlays[lab_unit_number]
  if not overlay then return end

  overlay[4] = get_entity_rect(lab)

  local animation = overlay[2]
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

--- Rebuild the per-player view data from all connected players.
---
--- Call this whenever any player's position, zoom, or surface changes.
--- The first active player's force and position are used for color calculations.
function LabOverlayRenderer:update_player_views()
  local players = game.connected_players
  local player_views = self.player_views
  local n = 0

  for i = 1, #players do
    local player = players[i]
    if player.render_mode ~= RENDER_MODE_CHART then
      local player_position = player.position
      local pos_x = player_position.x
      local pos_y = player_position.y

      -- Use the first active player for force and position (used by color function).
      if n == 0 then
        self.player_force = player.force --[[@as LuaForce]]
        local self_player_position = self.player_position
        self_player_position[1] = pos_x
        self_player_position[2] = pos_y
      end

      local f = player.zoom * 64 -- * 32 (pixels per tile) * 2 (half)
      local display_resolution = player.display_resolution
      local half_view_width = ceil(display_resolution.width / f)
      local half_view_height = ceil(display_resolution.height / f)

      local view_left = pos_x - half_view_width - VIEW_RECT_MARGIN
      local view_top = pos_y - half_view_height - VIEW_RECT_MARGIN
      local view_right = pos_x + half_view_width + VIEW_RECT_MARGIN
      local view_bottom = pos_y + half_view_height + VIEW_RECT_MARGIN

      local chunk_left, chunk_top, chunk_right, chunk_bottom =
        rect_to_chunk_range({ view_left, view_top, view_right, view_bottom })

      n = n + 1
      local view = player_views[n]
      if not view then
        view = { 0, 0, 0, 0, 0 }
        player_views[n] = view
      end
      view[1] = player.surface_index
      view[2] = chunk_left
      view[3] = chunk_top
      view[4] = chunk_right
      view[5] = chunk_bottom
    end
  end

  -- Clear stale entries from previous calls with more players.
  for i = n + 1, #player_views do
    player_views[i] = nil
  end
end

--- Get a tick function to be called by on_tick event.
---
--- The function updates overlays in the chunk ranges visible to each connected player.
---
--- @return fun(event: EventData.on_tick)
function LabOverlayRenderer:get_tick_function()
  -- Because a tick function is critical for UPS (Updates Per Second), we should optimize it very tightly.
  --
  -- For optimization, as much as possible we should:
  -- * Avoid access to the same key on a table multiple times.
  -- * Avoid access to the same outer-scope variable (upvalue) multiple times.
  -- * Avoid function calls. Make it inline.
  -- * Avoid creating a new object.

  local color_registry = self.color_registry
  -- Capture the raw data table from ChunkMap for zero-overhead access in the hot path.
  local chunk_map_data = self.chunk_map.data
  -- Capture as upvalue: the table is mutated by update_player_views, not replaced.
  local player_views = self.player_views
  local player_position = self.player_position

  -- For temporary. This will go into settings.
  local hq = true

  local current_research = self.player_force and self.player_force.current_research
  local current_research_colors = current_research and color_registry:get_colors_for_research(current_research)

  local meandering_tick = 1
  local meandering_direction = 1
  local color_function_index, color_function = ColorFunctions.choose_random(hq)
  local color = { 0, 0, 0 }

  -- Tracks which chunks have already been processed this tick to avoid redundant
  -- updates when multiple players' views overlap. Mirrors chunk_map_data structure:
  -- chunk_ticks[surface_index][cx][cy] = current_tick.
  --- @type table<number, table<number, table<number, number>>>
  local chunk_ticks = {}
  local current_tick = 0

  return function ()
    -- Return early when no player is active (all disconnected or in chart mode).
    if not player_views[1] then return end

    -- `self.player_force` is always set when player_views is non-empty.
    local player_force = self.player_force --[[@as LuaForce]]
    if player_force.current_research ~= current_research then
      current_research = player_force.current_research
      current_research_colors = current_research and color_registry:get_colors_for_research(current_research)
    end

    -- `meandering_tick` goes up to 60, then goes down to 0, then repeat.
    -- On changing the direction, chooses a new color function.
    if meandering_tick == 60 then
      meandering_direction = -1
      color_function_index, color_function = ColorFunctions.choose_random(hq, color_function_index)
    elseif meandering_tick == 0 then
      meandering_direction = 1
      color_function_index, color_function = ColorFunctions.choose_random(hq, color_function_index)
    end
    meandering_tick = meandering_tick + meandering_direction
    current_tick = current_tick + 1

    -- We do this for performance
    local player_force_index = player_force.index
    local current_research_colors = current_research_colors --- @diagnostic disable-line: redefined-local
    local player_position = player_position                 --- @diagnostic disable-line: redefined-local
    local meandering_tick = meandering_tick                 --- @diagnostic disable-line: redefined-local
    local color_function = color_function                   --- @diagnostic disable-line: redefined-local
    local color = color                                     --- @diagnostic disable-line: redefined-local
    local STATUS_WORKING = STATUS_WORKING                   --- @diagnostic disable-line: redefined-local
    local STATUS_LOW_POWER = STATUS_LOW_POWER               --- @diagnostic disable-line: redefined-local
    local current_tick = current_tick                       --- @diagnostic disable-line: redefined-local
    local chunk_ticks = chunk_ticks                         --- @diagnostic disable-line: redefined-local

    -- Update overlays in the chunk ranges visible to each connected player.
    -- chunk_ticks ensures each chunk is processed at most once per tick,
    -- even when multiple players' views overlap.
    for i = 1, #player_views do
      local view = player_views[i]
      local surface_index = view[1]
      local surface_chunks = chunk_map_data[surface_index]
      if surface_chunks then
        local chunk_left = view[2]
        local chunk_top = view[3]
        local chunk_right = view[4]
        local chunk_bottom = view[5]

        local ticks_surface = chunk_ticks[surface_index]
        if not ticks_surface then
          ticks_surface = {}
          chunk_ticks[surface_index] = ticks_surface
        end

        for cx = chunk_left, chunk_right do
          local col = surface_chunks[cx]
          if col then
            local ticks_col = ticks_surface[cx]
            if not ticks_col then
              ticks_col = {}
              ticks_surface[cx] = ticks_col
            end

            for cy = chunk_top, chunk_bottom do
              local chunk = col[cy]
              if chunk and ticks_col[cy] ~= current_tick then
                ticks_col[cy] = current_tick

                for _, overlay in pairs(chunk) do
                  local entity = overlay[1]
                  local animation = overlay[2]
                  local entity_position = overlay[3]

                  local status = entity.status
                  local is_visible = (
                    (status == STATUS_WORKING or status == STATUS_LOW_POWER) and
                    current_research_colors ~= nil and
                    entity.force_index == player_force_index
                  )

                  if animation.visible ~= is_visible then
                    animation.visible = is_visible
                  end

                  if is_visible then
                    --- @cast current_research_colors ColorTuple[]
                    color_function(color, meandering_tick, current_research_colors, player_position, entity_position)
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
end

return LabOverlayRenderer
