local ColorFunctions = require("scripts.runtime.color-functions")
local ChunkMap = require("scripts.runtime.chunk-map")
local Settings = require("scripts.shared.settings")

--- @class LabOverlayRenderer
local LabOverlayRenderer = {}
LabOverlayRenderer.__index = LabOverlayRenderer

local random = math.random
local max = math.max
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
--- @field companion    LuaRenderObject? Render object for the companion, which is rendered over the overlay but not colorizeed.
--- @field x            number           X coordinate.
--- @field y            number           Y coordinate.
--- @field visible      boolean          Last known visible state of the animation (cached, avoids repeated C bridge reads).
--- @field unit_number  number           Unit number of the lab entity (required by ChunkMap for swap-and-pop removal).
--- @field force_index  number           Force index of the lab entity (cached, avoids C bridge read in tick function).
--- @field player_index integer          Index of the player viewing this overlay (set by state_update_function).

--- @class (exact) ForceState
--- @field current_research LuaTechnology|nil Current researching technology.
--- @field colors           number[]|nil      Flattened colors array in format: `{ r, g, b, r, g, b... }`
--- @field n_colors         integer           Number of colors.

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

    --- Spatial chunk-based map for the overlays.
    --- @type ChunkMap
    chunk_map = ChunkMap.new(),

    --- Per-force state for the tick function. Key is force.index.
    --- @type table<number, ForceState|nil>
    force_state = {},

    --- Flattened list of lab overlays currently in any player's view.
    --- @type LabOverlay[]
    visible_overlays = {},

    --- Current dynamic interval (throttled based on load).
    current_interval = 1,
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
    -- Check if settings change for avoiding setting same value which forces re-rendaring.
    if render_object.animation ~= animation then
      render_object.animation = animation
    end
    if render_object.x_scale ~= scale then
      render_object.x_scale = scale
    end
    if render_object.y_scale ~= scale then
      render_object.y_scale = scale
    end
  else
    render_object = draw_animation({
      animation = animation,
      surface = lab.surface,
      target = lab,
      x_scale = scale,
      y_scale = scale,
      render_layer = "higher-object-under",
      visible = false,
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
  elseif companion then
    companion_object = draw_animation({
      animation = companion,
      surface = lab.surface,
      target = lab,
      x_scale = scale,
      y_scale = scale,
      -- "object" < "cargo-hatch" < "higher-object-under" < "higher-object-above"
      render_layer = is_companion_under_overlay and "cargo-hatch" or "higher-object-above",
      visible = render_object.visible,
      animation_offset = render_object.animation_offset,
    })
  end

  local lab_position = lab.position
  local lab_x = lab_position.x or lab_position[1]
  local lab_y = lab_position.y or lab_position[2]

  --- @type LabOverlay
  local new_overlay = {
    entity       = lab,
    animation    = render_object,
    companion    = companion_object,
    x            = lab_x,
    y            = lab_y,
    visible      = render_object.visible,
    unit_number  = lab_unit_number,
    force_index  = lab.force_index,
    player_index = 0, -- set by state_update_function
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

  -- Reset data structures.
  self.overlays = {}
  self.chunk_map = ChunkMap.new()
  self.visible_overlays = {}
  self.force_state = {}

  self:update_all_forces_current_research()

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

  local overlay = self.overlays[lab_unit_number]
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
  self.overlays[lab_unit_number] = nil

  -- We do not remove the overlay from the visible_overlays here because it is rebuilt every 30 ticks.
  -- The tick function checks the animation.valid so it does not cause a crash by setting a color to the destroyed object.
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
        local unit_number = overlay.unit_number
        local animation = overlay.animation
        if animation.valid then
          animation.destroy()
        end
        local companion = overlay.companion
        if companion and companion.valid then
          companion.destroy()
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
--- @param lab LuaEntity The lab entity. Must be valid.
function LabOverlayRenderer:update_lab_position(lab)
  local lab_unit_number = lab.unit_number
  if not lab_unit_number then return end

  local overlay = self.overlays[lab_unit_number]
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
    self.overlays[lab_unit_number] = nil
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

--- Update force_state by the force's current_research.
---
--- It does nothing if force_state for the force does not exist.
---
--- @param force LuaForce
function LabOverlayRenderer:update_force_current_research(force)
  local force_index = force.index
  local fs = self.force_state[force_index]
  if not fs then return end

  local force_current_research = force.current_research
  fs.current_research = force_current_research

  if force_current_research then
    local colors = self.color_registry:get_colors_for_research(force_current_research, Settings.color_saturation, Settings.color_brightness)
    local n_colors = #colors

    -- Flatten the color tuples into a single array for performance in the hot tick function.
    local flat_colors = {}
    local color_index = 1
    for i = 1, n_colors do
      local c = colors[i]
      flat_colors[color_index] = c[1]
      flat_colors[color_index + 1] = c[2]
      flat_colors[color_index + 2] = c[3]
      color_index = color_index + 3
    end

    fs.colors = flat_colors
    fs.n_colors = n_colors
  else
    fs.colors = nil
    fs.n_colors = 0
  end
end

--- Update force_state for all tracked forces by their current_research.
function LabOverlayRenderer:update_all_forces_current_research()
  local forces = game.forces
  for force_index in pairs(self.force_state) do
    local force = forces[force_index]
    if force then
      self:update_force_current_research(force)
    end
  end
end

--- Compute the chunk range visible to a player.
---
--- @param player LuaPlayer
--- @return integer chunk_left
--- @return integer chunk_top
--- @return integer chunk_right
--- @return integer chunk_bottom
local function compute_player_view(player)
  local player_position = player.position
  local px = player_position.x or player_position[1]
  local py = player_position.y or player_position[2]

  local f = player.zoom * 64 --[[$TILE_SIZE * 2]]
  local display_resolution = player.display_resolution
  local half_vw = ceil(display_resolution.width / f)
  local half_vh = ceil(display_resolution.height / f)

  return
    floor((px - half_vw - 6 --[[$VIEW_RECT_MARGIN]]) / 32 --[[$CHUNK_SIZE]]),
    floor((py - half_vh - 6 --[[$VIEW_RECT_MARGIN]]) / 32 --[[$CHUNK_SIZE]]),
    floor((px + half_vw + 6 --[[$VIEW_RECT_MARGIN]]) / 32 --[[$CHUNK_SIZE]]),
    floor((py + half_vh + 6 --[[$VIEW_RECT_MARGIN]]) / 32 --[[$CHUNK_SIZE]])
end

--- Get a state update function to be called every 30 ticks.
---
--- The returned function:
---   - Tracks current_research per force and updates force_state when it changes.
---   - Checks lab entity.status and updates overlay.visible and animation.visible.
---   - Rebuilds self.visible_overlays for the tick function to iterate.
---   - Sets overlay.player_index for each visible overlay.
---
--- @return fun()
function LabOverlayRenderer:get_state_update_function()
  local force_state = self.force_state
  local chunk_map = self.chunk_map
  local visible_overlays = self.visible_overlays

  --- A weak-key table to check if a chunk is updated in the current call. Key is a chunk (table) itself.
  --- Value is a generation counter to avoid clearing between calls: stale entries are ignored.
  --- @type table<table, integer>
  local visited_chunk = setmetatable({}, { __mode = "k" })
  local generation = 0

  return function ()
    generation = generation + 1
    local gen = generation

    local chunk_map_data = chunk_map.data
    local remove_unit_numbers = nil --- @type number[]|nil
    local visible_overlay_count = 0
    for _, force in pairs(game.forces) do
      local connected_players = force.connected_players
      if #connected_players == 0 then goto next_force end

      local force_index = force.index

      -- Update force_state once per force.
      local fs = force_state[force_index]
      if not fs then
        fs = {
          current_research = nil,
          colors = nil,
          n_colors = 0,
        }
        force_state[force_index] = fs
      end
      if force.current_research ~= fs.current_research then
        self:update_force_current_research(force)
      end

      -- Process each connected player's view.
      for i = 1, #connected_players do
        local player = connected_players[i]
        if player.render_mode == RENDER_MODE_CHART then goto next_player end

        local player_index = player.index
        local surface_index = player.surface_index
        local chunk_left, chunk_top, chunk_right, chunk_bottom = compute_player_view(player)

        -- Iterate chunks in this player's view and build visible_overlays.
        local surface_chunks = chunk_map_data[surface_index]
        if surface_chunks then
          for cx = chunk_left, chunk_right do
            local col = surface_chunks[cx]
            if col then
              for cy = chunk_top, chunk_bottom do
                local chunk = col[cy]
                if chunk then
                  -- Skip chunks already processed in this call (visible to multiple players).
                  if visited_chunk[chunk] == gen then goto next_chunk end
                  visited_chunk[chunk] = gen

                  for j = 1, #chunk do
                    local overlay = chunk[j]
                    local entity = overlay.entity

                    -- If entity is invalid, remove the overlay later
                    if not entity.valid then
                      if not remove_unit_numbers then remove_unit_numbers = {} end
                      remove_unit_numbers[#remove_unit_numbers + 1] = overlay.unit_number
                      goto next_overlay
                    end

                    local status = entity.status
                    local lab_fs = force_state[overlay.force_index]
                    local colors = lab_fs and lab_fs.colors
                    local is_visible = (
                      (status == STATUS_WORKING or status == STATUS_LOW_POWER) and
                      colors ~= nil
                    )
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
                      overlay.player_index = player_index
                    end

                    ::next_overlay::
                  end

                  ::next_chunk::
                end
              end
            end
          end
        end

        ::next_player::
      end

      ::next_force::
    end

    -- Clear trailing lab overlay references from the table to prevent memory leaks and GC issues.
    -- Setting elements to nil ensures that #visible_overlays accurately reflects the current count.
    for i = visible_overlay_count + 1, #visible_overlays do
      if visible_overlays[i] == nil then break end
      visible_overlays[i] = nil
    end

    -- Remove overlays for invalid entities
    if remove_unit_numbers then
      for i = 1, #remove_unit_numbers do
        self:remove_overlay_from_lab(remove_unit_numbers[i])
      end
    end

    -- Update dynamic interval based on the number of visible overlays.
    -- Automatically extend the interval if there are more than 500 visible labs.
    local max_updates = 500 --[[$MAX_UPDATES_PER_TICK]]
    local interval = (visible_overlay_count > max_updates) and ceil(visible_overlay_count / max_updates) or 1
    if interval > 60 then interval = 60 end
    self.current_interval = interval
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
    phase = 0,
    phase_speed = random_phase_speed(),
    color_function_index = color_function_index,
    saved_tick = game.tick,
  }) --[[@as AnimState]]
end

--- Get a tick function to be called by on_tick event.
---
--- The function updates colors of overlays in self.visible_overlays.
---
--- @param anim_state AnimState
--- @return fun()
function LabOverlayRenderer:get_tick_function(anim_state)
  -- Because a tick function is critical for UPS (Updates Per Second), we should optimize it very tightly.
  --
  -- For optimization, as much as possible we should:
  -- * Avoid access to the same key on a table multiple times.
  -- * Avoid function calls. Make it inline.
  -- * Avoid creating a new object.
  -- * Avoid access to native objects provided by Factorio. C bridge call is expensive.

  local visible_overlays = self.visible_overlays
  local force_state = self.force_state
  local color_pattern_duration = ceil(Settings.color_pattern_duration / Settings.color_update_interval)

  -- Resume from stored state, accounting for ticks elapsed since it was last persisted.
  -- This ensures animation is continuous across load/configuration_changed transitions.
  local color_pattern_elapsed = max(0, game.tick - anim_state.saved_tick) -- max is just for safety
  local phase = anim_state.phase + color_pattern_elapsed * anim_state.phase_speed
  local phase_speed = anim_state.phase_speed
  local color_function_index = anim_state.color_function_index
  local color_function = ColorFunctions.functions[color_function_index]
  local color = { 0, 0, 0 }
  local lab_update_offset = 1

  return function ()
    -- Return early when no overlays are visible (no player active, or no research in progress).
    -- `visible_overlays` is captured once at closure creation; it is mutated in-place by get_state_update_function().
    local n_visible_overlays = #visible_overlays
    if n_visible_overlays == 0 then return end

    phase = phase + phase_speed

    color_pattern_elapsed = color_pattern_elapsed + 1
    if color_pattern_elapsed >= color_pattern_duration then
      color_pattern_elapsed = 0
      color_function, color_function_index = ColorFunctions.choose_random(color_function_index)
      phase_speed = random_phase_speed()

      -- Persist so that the next tick function (after reload or settings change) can resume mid-epoch.
      anim_state.phase = phase
      anim_state.phase_speed = phase_speed
      anim_state.color_function_index = color_function_index
      anim_state.saved_tick = game.tick
    end

    local current_interval = self.current_interval
    lab_update_offset = lab_update_offset + 1
    if lab_update_offset > current_interval then lab_update_offset = 1 end

    -- Cache colors by force index and player position by player index to avoid repeated lookups.
    -- In the common case (all labs under one force/player), this avoids all but the first lookup.
    local last_force_index = -1
    local colors = nil
    local n_colors = 0
    local last_player_index = -1
    local player_x = 0
    local player_y = 0

    -- Update colors of the visible overlays using stride iteration
    for i = lab_update_offset, n_visible_overlays, current_interval do
      local overlay = visible_overlays[i]
      local force_index = overlay.force_index
      if force_index ~= last_force_index then
        last_force_index = force_index
        local fs = force_state[force_index]
        if fs then
          colors = fs.colors
          n_colors = fs.n_colors
        else
          colors = nil
        end
      end
      if colors then
        local player_index = overlay.player_index
        if player_index ~= last_player_index then
          last_player_index = player_index
          local player = game.get_player(player_index)
          if player then
            local pos = player.position
            player_x = pos.x or pos[1]
            player_y = pos.y or pos[2]
          else
            player_x = 0
            player_y = 0
          end
        end
        color_function(color, phase, colors, n_colors, player_x, player_y, overlay.x, overlay.y)

        local animation = overlay.animation
        if animation.valid then
          animation.color = color
        elseif overlay.entity.valid then
          self:render_overlay_for_lab(overlay.entity)
        end
        -- We ignore the invalid entity. The overlay will be destroyed by the `on_object_destroyed` handler.
      end
    end
  end
end

return LabOverlayRenderer
