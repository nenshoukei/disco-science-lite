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

    --- Chunk range visible to the player. nil when no player is active.
    --- @type PlayerView|nil
    player_view = nil,

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
--- @param lab_unit_number number The unit_number of the removed lab entity.
function LabOverlayRenderer:remove_overlay_from_lab(lab_unit_number)
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
      for unit_number in pairs(chunk) do
        local overlay = overlays[unit_number]
        if overlay then
          local animation = overlay[2]
          if animation.valid then
            animation.destroy()
          end
          overlays[unit_number] = nil
        end
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

--- Rebuild the view data from the single connected player.
---
--- Call this whenever the player's position, zoom, or surface changes.
--- Does nothing if multiplayer (more than one connected player).
function LabOverlayRenderer:update_player_view()
  local players = game.connected_players

  -- This mod is single-player only. Do not update in multiplayer.
  if #players ~= 1 then
    self.player_view = nil
    return
  end

  local player = players[1]
  if player.render_mode == RENDER_MODE_CHART then
    self.player_view = nil
    return
  end

  self.player_force = player.force --[[@as LuaForce]]

  local player_position = player.position
  local pos_x = player_position.x
  local pos_y = player_position.y
  local self_player_position = self.player_position
  self_player_position[1] = pos_x
  self_player_position[2] = pos_y

  local f = player.zoom * 64 -- * 32 (pixels per tile) * 2 (half)
  local display_resolution = player.display_resolution
  local half_view_width = ceil(display_resolution.width / f)
  local half_view_height = ceil(display_resolution.height / f)

  local view_rect = {
    pos_x - half_view_width - VIEW_RECT_MARGIN,
    pos_y - half_view_height - VIEW_RECT_MARGIN,
    pos_x + half_view_width + VIEW_RECT_MARGIN,
    pos_y + half_view_height + VIEW_RECT_MARGIN,
  }
  local chunk_left, chunk_top, chunk_right, chunk_bottom = rect_to_chunk_range(view_rect)

  -- Update in-place
  local view = self.player_view
  if not view then
    view = { 0, 0, 0, 0, 0 }
    self.player_view = view
  end
  view[1] = player.surface_index
  view[2] = chunk_left
  view[3] = chunk_top
  view[4] = chunk_right
  view[5] = chunk_bottom
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
  -- * Avoid access to the same outer-scope variable (upvalue) multiple times.
  -- * Avoid function calls. Make it inline.
  -- * Avoid creating a new object.

  local color_registry = self.color_registry
  local chunk_map_data = self.chunk_map.data
  local player_position = self.player_position

  -- For temporary. This will go into settings.
  local hq = true

  local current_research = self.player_force and self.player_force.current_research
  local current_research_colors = current_research and color_registry:get_colors_for_research(current_research)

  local meandering_tick = 1
  local meandering_direction = 1
  local color_function_index, color_function = ColorFunctions.choose_random(hq)
  local color = { 0, 0, 0 }

  return function ()
    -- Return early when no player is active (disconnected or in chart mode).
    local player_view = self.player_view
    if not player_view then return end

    -- `self.player_force` is always set when player_view is non-nil.
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

    -- We do this for performance
    local player_force_index = player_force.index
    local current_research_colors = current_research_colors --- @diagnostic disable-line: redefined-local
    local player_position = player_position                 --- @diagnostic disable-line: redefined-local
    local meandering_tick = meandering_tick                 --- @diagnostic disable-line: redefined-local
    local color_function = color_function                   --- @diagnostic disable-line: redefined-local
    local color = color                                     --- @diagnostic disable-line: redefined-local
    local STATUS_WORKING = STATUS_WORKING                   --- @diagnostic disable-line: redefined-local
    local STATUS_LOW_POWER = STATUS_LOW_POWER               --- @diagnostic disable-line: redefined-local

    -- Update overlays in the chunk range visible to the player.
    local surface_chunks = chunk_map_data[player_view[1]]
    if surface_chunks then
      local chunk_left = player_view[2]
      local chunk_top = player_view[3]
      local chunk_right = player_view[4]
      local chunk_bottom = player_view[5]

      for cx = chunk_left, chunk_right do
        local col = surface_chunks[cx]
        if col then
          for cy = chunk_top, chunk_bottom do
            local chunk = col[cy]
            if chunk then
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

return LabOverlayRenderer
