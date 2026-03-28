local ColorFunctions = require("scripts.runtime.color-functions")
local ChunkMap = require("scripts.runtime.chunk-map")
local Settings = require("scripts.shared.settings")

--- @class LabOverlayRenderer
local LabOverlayRenderer = {}
LabOverlayRenderer.__index = LabOverlayRenderer

local random = math.random
local max = math.max
local min = math.min
local ceil = math.ceil
local floor = math.floor
local rendering_clear = rendering.clear
local rendering_get_all_objects = rendering.get_all_objects
local draw_animation = rendering.draw_animation
local STATUS_WORKING = defines.entity_status.working
local STATUS_LOW_POWER = defines.entity_status.low_power
local RENDER_MODE_CHART = defines.render_mode.chart

--- @class (exact) LabOverlay
--- @field entity       LuaEntity        Lab entity.
--- @field animation    LuaRenderObject  Render object for the overlay.
--- @field companion    LuaRenderObject? Render object for the companion, which is rendered over the overlay but not colorized.
--- @field x            number           X coordinate.
--- @field y            number           Y coordinate.
--- @field visible      boolean          Last known visible state of the animation (cached, avoids repeated C bridge reads).
--- @field unit_number  number           Unit number of the lab entity (required by ChunkMap for swap-and-pop removal).

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

    --- Spatial chunk-based map for the overlays.
    --- @type ChunkMap
    chunk_map = ChunkMap.new(),
  }
  self = setmetatable(self, LabOverlayRenderer)
  return self
end

--- Render an overlay for a lab entity.
---
--- @param lab LuaEntity The lab entity. Must be valid.
--- @param existing_overlay LuaRenderObject? An existing overlay render object to reuse (optional, used when rebuilding all). Must be valid.
--- @param existing_companion LuaRenderObject? An existing companion render object to reuse. Must be valid.
--- @return LabOverlay|nil # The rendered overlay. `nil` if the lab is not target.
function LabOverlayRenderer:render_overlay_for_lab(lab, existing_overlay, existing_companion)
  local lab_name = lab.name
  if self.lab_registry:is_excluded(lab_name) then return nil end

  local registration = self.lab_registry:get_registration(lab_name)
  if not registration and not Settings.is_fallback_enabled then
    return nil
  end

  local lab_unit_number = lab.unit_number
  if not lab_unit_number then return nil end

  local status = lab.status
  local is_visible = (status == STATUS_WORKING or status == STATUS_LOW_POWER) and lab.force.current_research ~= nil

  local animation                  --- @type string
  local companion                  --- @type string|nil
  local is_companion_under_overlay --- @type boolean|nil
  local scale                      --- @type number
  if registration then
    -- If lab is registered but no overlay animation specified, use animation for the standard Factorio lab.
    animation = registration.animation or "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]]
    companion = registration.companion
    is_companion_under_overlay = registration.is_companion_under_overlay
    scale = registration.scale or 1
  else
    -- Fallback: use a generic glow animation for labs without a registered overlay sprite.
    -- Scale the overlay to fit the lab's tile size. The fallback sprite covers 2 tiles at scale=1.
    local prototype = lab.prototype
    animation = "mks-dsl-general-overlay" --[[$GENERAL_OVERLAY_ANIMATION_NAME]]
    scale = max(prototype.tile_width, prototype.tile_height) * 0.5
  end

  local render_object --- @type LuaRenderObject
  if existing_overlay then
    -- If existing rendering object given, just update it with the registered values.
    render_object = existing_overlay
    -- Check if settings change for avoiding setting same value which forces re-rendering.
    if render_object.animation ~= animation then
      render_object.animation = animation
    end
    if render_object.x_scale ~= scale then
      render_object.x_scale = scale
    end
    if render_object.y_scale ~= scale then
      render_object.y_scale = scale
    end
    if render_object.visible ~= is_visible then
      render_object.visible = is_visible
    end
  else
    render_object = draw_animation({
      animation = animation,
      surface = lab.surface,
      target = lab,
      x_scale = scale,
      y_scale = scale,
      render_layer = "higher-object-under",
      visible = is_visible,
      animation_offset = random() * 300,
    })
  end

  local companion_object --- @type LuaRenderObject?
  if companion and existing_companion then
    companion_object = existing_companion
    if companion_object.animation ~= companion then
      companion_object.animation = companion
    end
    if companion_object.x_scale ~= scale then
      companion_object.x_scale = scale
    end
    if companion_object.y_scale ~= scale then
      companion_object.y_scale = scale
    end
    if companion_object.visible ~= is_visible then
      companion_object.visible = is_visible
    end
  elseif companion then
    companion_object = draw_animation({
      animation = companion,
      surface = lab.surface,
      target = lab,
      x_scale = scale,
      y_scale = scale,
      -- "object" < "cargo-hatch" < "higher-object-under" < "higher-object-above"
      render_layer = is_companion_under_overlay and "cargo-hatch" or "higher-object-above",
      visible = is_visible,
      animation_offset = render_object.animation_offset,
    })
  end

  local lab_position = lab.position
  local lab_x = lab_position.x or lab_position[1]
  local lab_y = lab_position.y or lab_position[2]

  --- @type LabOverlay
  local new_overlay = {
    entity      = lab,
    animation   = render_object,
    companion   = companion_object,
    x           = lab_x,
    y           = lab_y,
    visible     = false, -- authoritative visible state is set by the tick scan
    unit_number = lab_unit_number,
  }

  self.chunk_map:insert(lab, new_overlay)

  -- Register the lab entity to be notified by `on_object_destroyed` when it is destroyed.
  script.register_on_object_destroyed(lab)

  return new_overlay
end

--- Render overlays for all lab entities.
---
--- The tick function returned by `get_tick_function()` should be refreshed afterwards.
---
--- @param force boolean? If `true`, it destroys all overlays and re-render all overlays. Default: `false`.
function LabOverlayRenderer:render_overlays_for_all_labs(force)
  --- @type table<integer, LuaRenderObject>
  local existing_overlays = {}
  --- @type table<integer, LuaRenderObject>
  local existing_companions = {}
  if force then
    -- Destroy all rendering objects
    rendering_clear("disco-science-lite" --[[$MOD_NAME]])
  else
    -- Collect all existing valid render objects from the mod.
    -- Index them by their target unit_number for fast lookup.
    local all_objects = rendering_get_all_objects("disco-science-lite" --[[$MOD_NAME]])
    for i = 1, #all_objects do
      local object = all_objects[i]
      local entity = object.target.entity
      local unit_number = entity and entity.valid and entity.unit_number
      if unit_number then
        if object.render_layer == "higher-object-under" then
          existing_overlays[unit_number] = object
        else
          existing_companions[unit_number] = object
        end
      else
        -- Destroy objects with no valid lab target.
        object.destroy()
      end
    end
  end

  -- Reset chunk map.
  self.chunk_map = ChunkMap.new()

  local entity_filter = { type = "lab" }
  for _, surface in pairs(game.surfaces) do
    local entities = surface.find_entities_filtered(entity_filter)
    for i = 1, #entities do
      local lab = entities[i]
      local unit_number = lab.valid and lab.unit_number or nil
      if unit_number then
        local existing_overlay = existing_overlays[unit_number]
        local existing_companion = existing_companions[unit_number]

        -- Rebuild the overlay, reusing the existing render object if found.
        local new_overlay = self:render_overlay_for_lab(lab, existing_overlay, existing_companion)

        if new_overlay then
          -- Successfully reused or created. Remove from the map so it's not destroyed.
          existing_overlays[unit_number] = nil
          if new_overlay.companion then
            existing_companions[unit_number] = nil
          end
        end
      end
    end
  end

  -- Destroy any remaining render objects that were not reused.
  for _, object in pairs(existing_overlays) do
    object.destroy()
  end
  for _, object in pairs(existing_companions) do
    object.destroy()
  end
end

--- Remove the overlay from the lab entity.
---
--- @param lab_unit_number number The unit_number of the removed lab entity.
function LabOverlayRenderer:remove_overlay_from_lab(lab_unit_number)
  if not lab_unit_number then return end

  local overlay = self.chunk_map:get(lab_unit_number)
  if not overlay then return end

  local animation = overlay.animation
  if animation.valid then
    animation.destroy()
  end

  local companion = overlay.companion
  if companion and companion.valid then
    companion.destroy()
  end

  self.chunk_map:remove(lab_unit_number)

  -- We do not remove the overlay from the visible_overlays here because it is rebuilt every ~30 state updates.
  -- The color update checks animation.valid so it does not crash by setting a color on a destroyed object.
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

  local entries = self.chunk_map.entries
  for _, col in pairs(surface_chunks) do
    for _, chunk in pairs(col) do
      for i = 1, #chunk do
        local overlay = chunk[i]
        local unit_number = overlay.unit_number
        local animation = overlay.animation
        if animation.valid then
          animation.destroy()
        end
        local companion = overlay.companion
        if companion and companion.valid then
          companion.destroy()
        end
        entries[unit_number] = nil
      end
    end
  end

  self.chunk_map.data[surface_index] = nil
end

--- Update the lab entity position for updating its overlay.
---
--- @param lab LuaEntity The lab entity. Must be valid.
function LabOverlayRenderer:update_lab_position(lab)
  local lab_unit_number = lab.unit_number
  if not lab_unit_number then return end

  local overlay = self.chunk_map:get(lab_unit_number)
  if not overlay then return end

  local lab_position = lab.position
  local lab_x = lab_position.x or lab_position[1]
  local lab_y = lab_position.y or lab_position[2]
  overlay.x = lab_x
  overlay.y = lab_y

  local animation = overlay.animation
  local companion = overlay.companion
  if not animation.valid or (companion and not companion.valid) then
    -- Render object was destroyed externally; re-render from scratch.
    self.chunk_map:remove(lab_unit_number)
    self:render_overlay_for_lab(lab)
  elseif animation.surface.index == lab.surface_index then
    -- Same surface: update animation target and chunk map if chunk changed.
    animation.target = lab
    if companion then companion.target = lab end
    self.chunk_map:insert(lab, overlay) -- updates the existing entry
  else
    -- The entity is teleported to another surface!
    animation.destroy()
    if companion then companion.destroy() end
    self:render_overlay_for_lab(lab)
  end
end

--- Returns a random phase_speed value in { [-3.0, -0.5) or [0.5, 3.0) } / 40.
--- @return number
local function random_phase_speed()
  return (((random() * 5 + 3.5) % 6) - 3) * 0.025
end

--- Create an initial animation state based on the current game tick.
---
--- @return AnimState
function LabOverlayRenderer.create_anim_state()
  local _, color_function_index = ColorFunctions.choose_random()
  return ({
    phase_base = 0,
    phase_speed = random_phase_speed(),
    color_function_index = color_function_index,
    saved_tick = game.tick,
  }) --[[@as AnimState]]
end

--- Get a tick function and a state update request function.
---
--- The tick function performs two roles:
---   1. State update (every ~30 calls, or on demand via request_state_update):
---      - Tracks current_research for the player's force and updates colors when it changes.
---      - Updates player_position for the player.
---      - Checks lab entity.status and updates overlay visibility.
---      - Rebuilds visible_overlays for the color update to iterate.
---   2. Color update (every call):
---      - Updates colors of visible overlays using stride iteration.
---
--- The tick function should be refreshed after `render_overlays_for_all_labs()`.
---
--- @param anim_state AnimState
--- @return fun(event: EventData.on_tick) tick_function
--- @return fun() request_state_update
function LabOverlayRenderer:get_tick_function(anim_state)
  -- Because a tick function is critical for UPS (Updates Per Second), we should optimize it very tightly.
  --
  -- For optimization, as much as possible we should:
  -- * Avoid access to the same key on a table multiple times.
  -- * Avoid function calls. Make it inline.
  -- * Avoid creating a new object.
  -- * Avoid access to native objects provided by Factorio. C bridge call is expensive.

  local player = game.connected_players[1]
  if not player or game.is_multiplayer() then
    -- Return empty functions when player is not created yet or in multiplayer mode
    return function () end, function () end
  end

  local force = player.force --[[@as LuaForce]]
  local visible_overlays = {} --- @type LabOverlay[]
  local n_visible_overlays = 0
  local player_x = 0
  local player_y = 0
  local in_chart_mode = false

  -- Capture chunk_map.data (mutated in-place by ChunkMap)
  local chunk_map_data = self.chunk_map.data
  -- For inlined update_current_research
  local color_registry = self.color_registry

  -- Research state
  local state_update_counter = 0
  local force_state_update = true --- always force update at first tick
  local current_research = nil    --- @type LuaTechnology|nil
  local colors = nil              --- @type number[]|nil
  local n_colors = 0

  -- Animation state
  local color_pattern_duration = Settings.color_pattern_duration
  local color_update_offset = 1
  local color_update_stride = 1
  -- Resume from stored state, accounting for ticks elapsed since it was last persisted.
  -- This ensures animation is continuous across load/configuration_changed transitions.
  local color_pattern_saved_tick = min(anim_state.saved_tick, game.tick)
  local phase_base = anim_state.phase_base
  local phase_speed = anim_state.phase_speed
  local color_function_index = anim_state.color_function_index
  local color_function = ColorFunctions.functions[color_function_index]
  local color = { 0, 0, 0 }

  --- @param event EventData.on_tick
  local function tick_function(event)
    -- ========== State update (every ~30 calls or on demand) ==========
    state_update_counter = state_update_counter + 1
    if state_update_counter > 30 or force_state_update then
      state_update_counter = 0
      force_state_update = false

      in_chart_mode = player.render_mode == RENDER_MODE_CHART
      if in_chart_mode then return end -- Skip updates in chart mode

      -- Update current_research and colors if changed.
      local new_current_research = force.current_research
      if new_current_research == current_research then
        if new_current_research == nil then
          -- If current_research remains nil, we can safely skip visiblility and color updates. (all invisible)
          return
        end
      else
        current_research = new_current_research
        if current_research then
          local raw_colors = color_registry:get_colors_for_research(current_research, Settings.color_saturation, Settings.color_brightness)
          local raw_n_colors = #raw_colors
          -- Flatten the color tuples into a single array for performance in the hot color update loop.
          local flat_colors = {}
          local ci = 1
          for i = 1, raw_n_colors do
            local c = raw_colors[i]
            flat_colors[ci] = c[1]
            flat_colors[ci + 1] = c[2]
            flat_colors[ci + 2] = c[3]
            ci = ci + 3
          end
          colors = flat_colors
          n_colors = raw_n_colors
        else
          colors = nil
          n_colors = 0
        end
      end

      -- Update player position.
      local player_position = player.position
      player_x = player_position.x or player_position[1]
      player_y = player_position.y or player_position[2]

      -- Compute visible chunk range in player's view
      local f = player.zoom * 64 --[[$TILE_SIZE * 2]]
      local display_resolution = player.display_resolution
      local half_vw = display_resolution.width / f
      local half_vh = display_resolution.height / f
      local chunk_left = floor((player_x - half_vw - 6 --[[$VIEW_RECT_MARGIN]]) / 32 --[[$CHUNK_SIZE]])
      local chunk_top = floor((player_y - half_vh - 6 --[[$VIEW_RECT_MARGIN]]) / 32 --[[$CHUNK_SIZE]])
      local chunk_right = floor((player_x + half_vw + 6 --[[$VIEW_RECT_MARGIN]]) / 32 --[[$CHUNK_SIZE]])
      local chunk_bottom = floor((player_y + half_vh + 6 --[[$VIEW_RECT_MARGIN]]) / 32 --[[$CHUNK_SIZE]])

      -- Scan visible chunks for overlays and update their visibility
      local surface_chunks = chunk_map_data[player.surface_index]
      local visible_overlay_count = 0
      if surface_chunks then
        for cx = chunk_left, chunk_right do
          local col = surface_chunks[cx]
          if col then
            for cy = chunk_top, chunk_bottom do
              local chunk = col[cy]
              if chunk then
                for j = #chunk, 1, -1 do
                  local overlay = chunk[j]
                  local entity = overlay.entity

                  -- If entity is invalid, remove the overlay.
                  if not entity.valid then
                    self:remove_overlay_from_lab(overlay.unit_number)
                    goto next_overlay
                  end

                  local status = entity.status
                  local is_visible = (status == STATUS_WORKING or status == STATUS_LOW_POWER) and current_research ~= nil
                  if overlay.visible ~= is_visible then
                    overlay.visible = is_visible
                    overlay.animation.visible = is_visible
                    if overlay.companion then
                      overlay.companion.visible = is_visible
                    end
                  end

                  if is_visible then
                    visible_overlay_count = visible_overlay_count + 1
                    visible_overlays[visible_overlay_count] = overlay
                  end

                  ::next_overlay::
                end
              end
            end
          end
        end

        -- Clear trailing lab overlay references from the table to prevent memory leaks and GC issues.
        for i = visible_overlay_count + 1, n_visible_overlays do
          if visible_overlays[i] == nil then break end
          visible_overlays[i] = nil
        end
        n_visible_overlays = visible_overlay_count

        -- Update color_update_stride based on the number of visible overlays.
        -- Automatically extend the stride if there are more than 500 visible labs.
        color_update_stride = (n_visible_overlays > 500 --[[$MAX_UPDATES_PER_TICK]]) and ceil(n_visible_overlays / 500 --[[$MAX_UPDATES_PER_TICK]]) or 1
        if color_update_stride > 60 then color_update_stride = 60 end
      end
    end

    -- ========== Color update (every call) ==========

    if in_chart_mode or n_visible_overlays == 0 or not colors then return end

    local current_tick = event.tick
    local elapsed_tick = current_tick - color_pattern_saved_tick
    local phase = phase_base + phase_speed * elapsed_tick

    if elapsed_tick >= color_pattern_duration then
      color_function, color_function_index = ColorFunctions.choose_random(color_function_index)
      phase_speed = random_phase_speed()
      phase_base = phase
      color_pattern_saved_tick = current_tick

      -- Persist so that the next tick function (after reload or settings change) can resume mid-epoch.
      anim_state.phase_base = phase
      anim_state.phase_speed = phase_speed
      anim_state.color_function_index = color_function_index
      anim_state.saved_tick = current_tick
    end

    color_update_offset = color_update_offset + 1
    if color_update_offset > color_update_stride then color_update_offset = 1 end

    -- Update colors of the visible overlays using stride iteration.
    for i = color_update_offset, n_visible_overlays, color_update_stride do
      local overlay = visible_overlays[i]
      color_function(color, phase, colors, n_colors, player_x, player_y, overlay.x, overlay.y)

      local animation = overlay.animation
      if animation.valid then
        animation.color = color
      elseif overlay.entity.valid then
        self:render_overlay_for_lab(overlay.entity)
      else
        self:remove_overlay_from_lab(overlay.unit_number)
      end
    end
  end

  local function request_state_update()
    force_state_update = true
  end

  return tick_function, request_state_update
end

return LabOverlayRenderer
