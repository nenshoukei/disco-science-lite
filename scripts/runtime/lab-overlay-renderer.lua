local consts = require("scripts.shared.consts")
local config_target_labs = require("scripts.shared.config.target-labs")
local Utils = require("scripts.shared.utils")
local ColorFunctions = require("scripts.runtime.color-functions")

--- @class LabOverlayRenderer
local LabOverlayRenderer = {}
LabOverlayRenderer.__index = LabOverlayRenderer

if script then
  script.register_metatable("LabOverlayRenderer", LabOverlayRenderer)
end

local ceil = math.ceil
local floor = math.floor
local rendering_clear = rendering.clear
local draw_animation = rendering.draw_animation
local map_position_tuple = Utils.map_position_tuple
local get_entity_rect = Utils.get_entity_rect
local MOD_NAME = consts.MOD_NAME
local LAB_OVERLAY_ANIMATION_NAME = consts.LAB_OVERLAY_ANIMATION_NAME
local RENDER_MODE_CHART = defines.render_mode.chart
local STATUS_WORKING = defines.entity_status.working
local STATUS_LOW_POWER = defines.entity_status.low_power
local VIEW_RECT_MARGIN = 6 -- tiles
local CHUNK_SIZE = 32      -- tiles per chunk

--- @class LabEntityOverlay
--- @field [1] LuaEntity Lab entity.
--- @field [2] LuaRenderObject Render object for the overlay.
--- @field [3] MapPositionTuple Position of the entity.
--- @field [4] MapPositionRect Rectangle boundaries of the entity.
--- @field [5] number Surface index of the entity.
--- @field [6] number Chunk X coordinate of the entity.
--- @field [7] number Chunk Y coordinate of the entity.

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
    --- @type table<number, LabEntityOverlay>
    overlays = {},

    --- Overlays indexed by surface and chunk for efficient spatial lookup.
    --- chunks[surface_index][chunk_x][chunk_y][unit_number] = LabEntityOverlay
    --- @type table<number, table<number, table<number, table<number, LabEntityOverlay>>>>
    chunks = {},

    --- Player's position.
    --- @type MapPositionTuple
    player_position = { 0, 0 },

    --- Player's surface index.
    --- @type number
    player_surface_index = 0,

    --- Player's force.
    --- @type LuaForce|nil
    player_force = nil,

    --- Rectangle boundaries of the player's view.
    --- @type MapPositionRect
    view_rect = { 0, 0, 0, 0 },

    --- Mode of updating overlays.
    ---
    --- - `always` - Update all overlays including outside of the view.
    --- - `never` - No update.
    --- - `view` - Update all overlays inside the view.
    --- @type "always"|"never"|"view"
    update_mode = "always",
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

--- Insert an overlay into the chunk index.
---
--- @param chunks table<number, table<number, table<number, table<number, LabEntityOverlay>>>>
--- @param unit_number number
--- @param overlay LabEntityOverlay
local function insert_into_chunks(chunks, unit_number, overlay)
  local surface_index = overlay[5]
  local cx = overlay[6]
  local cy = overlay[7]
  local surface_chunks = chunks[surface_index]
  if not surface_chunks then
    surface_chunks = {}
    chunks[surface_index] = surface_chunks
  end
  local col = surface_chunks[cx]
  if not col then
    col = {}
    surface_chunks[cx] = col
  end
  local chunk_overlays = col[cy]
  if not chunk_overlays then
    chunk_overlays = {}
    col[cy] = chunk_overlays
  end
  chunk_overlays[unit_number] = overlay
end

--- Remove an overlay from the chunk index.
---
--- @param chunks table<number, table<number, table<number, table<number, LabEntityOverlay>>>>
--- @param unit_number number
--- @param overlay LabEntityOverlay
local function remove_from_chunks(chunks, unit_number, overlay)
  local surface_index = overlay[5]
  local cx = overlay[6]
  local cy = overlay[7]
  local surface_chunks = chunks[surface_index]
  if not surface_chunks then return end
  local col = surface_chunks[cx]
  if not col then return end
  local chunk_overlays = col[cy]
  if not chunk_overlays then return end
  chunk_overlays[unit_number] = nil
end

--- Render an overlay for a lab entity.
---
--- If the overlay already exists and `force_render` is `false`, skip rendering and returns the existing overlay.
---
--- @param lab LuaEntity The lab entity.
--- @param force_render boolean? If `true`, it renders the overlay even if it already exists.
--- @return LabEntityOverlay|nil # The rendered overlay. `nil` if the lab is not target.
function LabOverlayRenderer:render_overlay_for_lab(lab, force_render)
  if not lab.valid or lab.type ~= "lab" then return nil end

  local lab_unit_number = lab.unit_number
  if not lab_unit_number then return nil end

  local overlay = self.overlays[lab_unit_number]
  if overlay and not force_render then return overlay end

  local target_lab = self.target_labs[lab.name]
  if not target_lab then return nil end

  -- Remove old overlay from chunk index if force re-rendering.
  if overlay then
    remove_from_chunks(self.chunks, lab_unit_number, overlay)
  end

  local animation = draw_animation({
    animation = target_lab.animation,
    surface = lab.surface,
    target = lab,
    x_scale = target_lab.scale,
    y_scale = target_lab.scale,
    render_layer = "higher-object-under",
    visible = false,
  })

  local pos = map_position_tuple(lab.position)
  local surface_index = lab.surface_index
  local cx = floor(pos[1] / CHUNK_SIZE)
  local cy = floor(pos[2] / CHUNK_SIZE)

  local new_overlay = {
    lab,
    animation,
    pos,
    get_entity_rect(lab),
    surface_index,
    cx,
    cy,
  }

  self.overlays[lab_unit_number] = new_overlay
  insert_into_chunks(self.chunks, lab_unit_number, new_overlay)

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

  remove_from_chunks(self.chunks, lab_unit_number, overlay)
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
    -- Same surface: update animation target and chunk index if chunk changed.
    animation.target = lab

    local lab_position = lab.position
    local new_cx = floor((lab_position.x or lab_position[1]) / CHUNK_SIZE)
    local new_cy = floor((lab_position.y or lab_position[2]) / CHUNK_SIZE)
    if overlay[6] ~= new_cx or overlay[7] ~= new_cy then
      remove_from_chunks(self.chunks, lab_unit_number, overlay)
      overlay[6] = new_cx
      overlay[7] = new_cy
      insert_into_chunks(self.chunks, lab_unit_number, overlay)
    end
  else
    -- The entity is teleported to another surface!
    animation.destroy()
    remove_from_chunks(self.chunks, lab_unit_number, overlay)
    self.overlays[lab_unit_number] = nil
    self:render_overlay_for_lab(lab, true) -- Force re-render
  end
end

--- Update the player position for updating the overlays.
---
--- @param player LuaPlayer? If not given, `game.connected_players[1]` is used.
function LabOverlayRenderer:update_player_position(player)
  player = player or game.connected_players[1]
  if not player or player.render_mode == RENDER_MODE_CHART then
    self.update_mode = "never"
    return
  end

  local player_position = player.position
  local pos_x = player_position.x
  local pos_y = player_position.y

  local self_player_position = self.player_position
  self_player_position[1] = pos_x
  self_player_position[2] = pos_y

  self.player_force = player.force --[[@as LuaForce]]
  self.player_surface_index = player.surface_index

  if #game.connected_players > 1 then
    self.update_mode = "always"
  else
    self.update_mode = "view"

    local f = player.zoom * 64 -- * 32 (pixels per tile) * 2 (half)
    local display_resolution = player.display_resolution
    local half_view_width = ceil(display_resolution.width / f)
    local half_view_height = ceil(display_resolution.height / f)
    local self_view_rect = self.view_rect
    self_view_rect[1] = pos_x - half_view_width - VIEW_RECT_MARGIN
    self_view_rect[2] = pos_y - half_view_height - VIEW_RECT_MARGIN
    self_view_rect[3] = pos_x + half_view_width + VIEW_RECT_MARGIN
    self_view_rect[4] = pos_y + half_view_height + VIEW_RECT_MARGIN
  end
end

--- Get a tick function to be called by on_tick event.
---
--- The function updates overlays depending on `update_mode`.
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

  local overlays = self.overlays
  local chunks = self.chunks
  local player_position = self.player_position
  local view_rect = self.view_rect

  -- For temporary. This will go into settings.
  local hq = true

  local current_research = self.player_force and self.player_force.current_research
  local current_research_colors = current_research and self.color_registry:get_colors_for_research(current_research)

  local meandering_tick = 1
  local meandering_direction = 1
  local color_function_index, color_function = ColorFunctions.choose_random(hq)
  local color = { 0, 0, 0 }

  --- @param event EventData.on_tick
  return function (event)
    -- Note: String comparison in Lua is light-foot, because they are interned and compared by their addresses.
    local update_mode = self.update_mode
    if update_mode == "never" then return end
    local is_always_update = update_mode == "always"

    -- `self.player_force` is always set when update_mode is not `never`.
    local player_force = self.player_force --[[@as LuaForce]]
    if player_force.current_research ~= current_research then
      current_research = player_force.current_research
      current_research_colors = current_research and self.color_registry:get_colors_for_research(current_research)
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

    if is_always_update then
      -- In `always` mode, update all overlays on all surfaces.
      for _, overlay in pairs(overlays) do
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
    else
      -- In `view` mode, only update overlays in chunks that overlap the view rect.
      -- This avoids iterating all labs when most of them are off-screen.
      local view_rect = view_rect                           --- @diagnostic disable-line: redefined-local
      local surface_chunks = chunks[self.player_surface_index]
      if not surface_chunks then return end

      local chunk_left   = floor(view_rect[1] / CHUNK_SIZE)
      local chunk_top    = floor(view_rect[2] / CHUNK_SIZE)
      local chunk_right  = floor(view_rect[3] / CHUNK_SIZE)
      local chunk_bottom = floor(view_rect[4] / CHUNK_SIZE)

      for cx = chunk_left, chunk_right do
        local col = surface_chunks[cx]
        if col then
          for cy = chunk_top, chunk_bottom do
            local chunk_overlays = col[cy]
            if chunk_overlays then
              for _, overlay in pairs(chunk_overlays) do
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
