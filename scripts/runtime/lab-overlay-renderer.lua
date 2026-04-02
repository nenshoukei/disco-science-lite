local ColorFunctions = require("scripts.runtime.color-functions")
local ChunkMap = require("scripts.runtime.chunk-map")
local Settings = require("scripts.shared.settings")
local Utils = require("scripts.shared.utils")

--- @class LabOverlayRenderer
local LabOverlayRenderer = {}
LabOverlayRenderer.__index = LabOverlayRenderer

local random = math.random
local max = math.max
local ceil = math.ceil
local rendering_clear = rendering.clear
local rendering_get_all_objects = rendering.get_all_objects
local draw_animation = rendering.draw_animation
local map_position_tuple = Utils.map_position_tuple
local STATUS_WORKING = defines.entity_status.working
local STATUS_LOW_POWER = defines.entity_status.low_power
local RENDER_MODE_CHART = defines.render_mode.chart

--- @class (exact) LabOverlay
--- @field entity        LuaEntity        Lab entity.
--- @field animation     LuaRenderObject  Render object for the overlay.
--- @field companion     LuaRenderObject? Render object for the companion, which is rendered over the overlay but not colorized.
--- @field x             number           X coordinate.
--- @field y             number           Y coordinate.
--- @field visible       boolean          Last known visible state of the animation (cached, avoids repeated C bridge reads).
--- @field unit_number   number           Unit number of the lab entity (required by ChunkMap for swap-and-pop removal).
--- @field force_index   number           Force index of the lab entity.
--- @field surface_index number           Surface index of the lab entity.
--- @field viewer_index  integer          Player index of the viewer for spatial color functions in multiplayer.

--- @class (exact) ForceResearchState
--- @field force            LuaForce          Force.
--- @field current_research LuaTechnology|nil Current researching technology in force.
--- @field colors           number[]|nil      Flatten colors for the research.
--- @field n_colors         integer           Number of colors. (#colors / 3)

--- @class (exact) PlayerViewportState
--- @field viewport_width  number
--- @field viewport_height number
--- @field chunk_left      number
--- @field chunk_top       number
--- @field chunk_right     number
--- @field chunk_bottom    number
--- @field surface_index   number
--- @field was_skipped     boolean  true if player was in chart mode or outside surface bounds
--- @field player_index    integer  player.index for overlay.viewer_index assignment

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

    --- Overlay animation RenderObject.id to lab entity unit_number.
    --- @type table<integer, integer>
    render_object_id_to_unit_number = {},
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

  -- If called without explicit reuse objects, try to reuse currently tracked objects for this lab.
  if not existing_overlay or not existing_companion then
    local current_overlay = self.chunk_map:get(lab_unit_number)
    if current_overlay then
      if not existing_overlay then
        local current_animation = current_overlay.animation
        if current_animation and current_animation.valid then
          existing_overlay = current_animation
        end
      end
      if not existing_companion then
        local current_companion = current_overlay.companion
        if current_companion and current_companion.valid then
          existing_companion = current_companion
        end
      end
    end
  end

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
    render_object = existing_overlay
    -- Check if settings changed; avoid setting the same value, which forces re-rendering.
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
      animation_offset = random() * 300, -- randomize start frame so labs don't all animate in sync
    })
    script.register_on_object_destroyed(render_object)
  end
  self.render_object_id_to_unit_number[render_object.id] = lab_unit_number

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
      animation_offset = render_object.animation_offset, -- sync with the overlay so they animate together
    })
    script.register_on_object_destroyed(companion_object)
  end
  if companion_object then
    self.render_object_id_to_unit_number[companion_object.id] = lab_unit_number
  end

  -- Companion was previously present but is not needed anymore (e.g. registration changed).
  if not companion and existing_companion and existing_companion.valid then
    self.render_object_id_to_unit_number[existing_companion.id] = nil
    existing_companion.destroy()
  end

  local lab_position = lab.position
  local lab_x = lab_position.x or lab_position[1]
  local lab_y = lab_position.y or lab_position[2]

  --- @type LabOverlay
  local new_overlay = {
    entity        = lab,
    animation     = render_object,
    companion     = companion_object,
    x             = lab_x,
    y             = lab_y,
    viewer_index  = 0,
    visible       = false, -- start as hidden; tick scan will synchronize this with entity.status
    unit_number   = lab_unit_number,
    force_index   = lab.force_index,
    surface_index = lab.surface_index,
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

  -- Reset chunk map and render object tracking.
  self.chunk_map = ChunkMap.new()
  self.render_object_id_to_unit_number = {}

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
--- The `request_viewport_update` returned by `get_tick_function()` should be called afterwards.
---
--- @param lab_unit_number number The unit_number of the removed lab entity.
--- @param skip_chunk_map_remove boolean? If `true`, skips removing from chunk_map. (Default: false)
function LabOverlayRenderer:remove_overlay_from_lab(lab_unit_number, skip_chunk_map_remove)
  if not lab_unit_number then return end

  local overlay = self.chunk_map:get(lab_unit_number)
  if not overlay then return end

  local animation = overlay.animation
  if animation.valid then
    -- Remove RenderObject registration first to avoid re-entrant loop via on_object_destroyed
    self.render_object_id_to_unit_number[animation.id] = nil
    animation.destroy()
  end

  local companion = overlay.companion
  if companion and companion.valid then
    self.render_object_id_to_unit_number[companion.id] = nil
    companion.destroy()
  end

  if not skip_chunk_map_remove then
    self.chunk_map:remove(lab_unit_number)
  end
end

--- Remove all overlays on the given surface.
---
--- Call this on `on_surface_deleted` or `on_surface_cleared`.
--- Destroys render objects if still valid (e.g. on surface clear), and cleans up Lua data structures.
---
--- The `request_viewport_update` returned by `get_tick_function()` should be called afterwards.
---
--- @param surface_index number
function LabOverlayRenderer:remove_overlays_on_surface(surface_index)
  local surface_chunks = self.chunk_map.data[surface_index]
  if not surface_chunks then return end

  local entries = self.chunk_map.entries
  for _, col in pairs(surface_chunks) do
    for _, chunk in pairs(col) do
      for i = 1, #chunk do
        local unit_number = chunk[i].unit_number
        self:remove_overlay_from_lab(unit_number, true)
        entries[unit_number] = nil
      end
    end
  end

  self.chunk_map:clear_surface(surface_index)
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
  overlay.force_index = lab.force_index

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
    self.render_object_id_to_unit_number[animation.id] = nil
    animation.destroy()
    if companion then
      self.render_object_id_to_unit_number[companion.id] = nil
      companion.destroy()
    end
    self:render_overlay_for_lab(lab)
  end
end

--- Called on `on_object_destroyed` event for RenderObject.
---
--- The `request_viewport_update` returned by `get_tick_function()` should be called afterwards.
---
--- @param object_id number
function LabOverlayRenderer:on_render_object_destroyed(object_id)
  local unit_number = self.render_object_id_to_unit_number[object_id]
  if not unit_number then return end

  self.render_object_id_to_unit_number[object_id] = nil -- Remove it to avoid memory-leaks

  local overlay = self.chunk_map:get(unit_number)
  if not overlay then return end

  if overlay.entity.valid then
    -- Lab entity still exists, but overlay (companion) animation is destroyed. Re-render it.
    self:remove_overlay_from_lab(unit_number)
    self:render_overlay_for_lab(overlay.entity)
  else
    -- Lab entity is also destroyed. Remove the overlay.
    self:remove_overlay_from_lab(unit_number)
  end
end

--- Hide all overlays that are currently visible.
---
--- Called when a player leaves the game to ensure labs from their viewport
--- do not remain colorized after they disconnect.
--- The tick function will re-show overlays for labs in the remaining players' viewports.
function LabOverlayRenderer:hide_all_overlays()
  for _, entry in pairs(self.chunk_map.entries) do
    local overlay = entry.overlay
    if overlay.visible then
      overlay.visible = false
      local animation = overlay.animation
      if animation.valid then
        animation.visible = false
      end
      local companion = overlay.companion
      if companion and companion.valid then
        companion.visible = false
      end
    end
  end
end

--- Returns a random phase_speed value in { [-3.0, -0.5) or [0.5, 3.0) } / 40.
--- @param generator LuaRandomGenerator? Optional random generator.
--- @return number
local function random_phase_speed(generator)
  local r = generator and generator() or random()
  return (((r * 5 + 3.5) % 6) - 3) * 0.025
end

--- Update research state for all forces.
--- @param force_states table<number, ForceResearchState>
--- @param color_registry ColorRegistry
--- @return boolean has_any_research
--- @return boolean research_changed
local function update_all_force_research_states(force_states, color_registry)
  local has_any_research = false
  local research_changed = false
  local saturation = Settings.color_saturation
  local brightness = Settings.color_brightness
  local is_rainbow_mode = Settings.is_rainbow_mode

  for _, state in pairs(force_states) do
    local new_current_research = state.force.current_research
    if new_current_research ~= state.current_research then
      state.current_research = new_current_research
      research_changed = true
      if new_current_research then
        if is_rainbow_mode then
          state.colors, state.n_colors = color_registry:get_flattened_rainbow_colors(saturation, brightness)
        else
          state.colors, state.n_colors = color_registry:get_flattened_colors_for_research(new_current_research, saturation, brightness)
        end
      else
        state.colors = nil
        state.n_colors = 0
      end
    end
    if new_current_research ~= nil then
      has_any_research = true
    end
  end
  return has_any_research, research_changed
end

--- Calculate chunk bounds for a player's viewport.
--- @param player_x number
--- @param player_y number
--- @param zoom number
--- @param viewport_width number
--- @param viewport_height number
--- @return number left
--- @return number top
--- @return number right
--- @return number bottom
local function calculate_viewport_chunks(player_x, player_y, zoom, viewport_width, viewport_height)
  local f = zoom * 64 --[[$TILE_SIZE * 2]]
  local half_vw = viewport_width / f
  local half_vh = viewport_height / f
  local l = (player_x - half_vw - 6 --[[$VIEW_RECT_MARGIN]]) / 32 --[[$CHUNK_SIZE]]
  local t = (player_y - half_vh - 6 --[[$VIEW_RECT_MARGIN]]) / 32 --[[$CHUNK_SIZE]]
  local r = (player_x + half_vw + 6 --[[$VIEW_RECT_MARGIN]]) / 32 --[[$CHUNK_SIZE]]
  local b = (player_y + half_vh + 6 --[[$VIEW_RECT_MARGIN]]) / 32 --[[$CHUNK_SIZE]]
  return l - l % 1, t - t % 1, r - r % 1, b - b % 1
end

--- Update a player's viewport state and detect changes.
--- @param player LuaPlayer
--- @param vstate PlayerViewportState
--- @param px number
--- @param py number
--- @param chunk_map ChunkMap
--- @return boolean changed
local function update_player_viewport_state(player, vstate, px, py, chunk_map)
  local surface_index = player.surface_index
  local surface_chunks = chunk_map.data[surface_index]

  if player.render_mode == RENDER_MODE_CHART or not surface_chunks then
    if vstate.was_skipped then return false end
    vstate.was_skipped = true
    return true
  end

  if chunk_map.surface_bounds_dirty[surface_index] then
    chunk_map:update_surface_bounds(surface_index)
  end
  local bounds = chunk_map.surface_bounds[surface_index]
  if not bounds or px < bounds[1] or px > bounds[3] or py < bounds[2] or py > bounds[4] then
    if vstate.was_skipped then return false end
    vstate.was_skipped = true
    return true
  end

  local cl, ct, cr, cb = calculate_viewport_chunks(px, py, player.zoom, vstate.viewport_width, vstate.viewport_height)
  if (
      vstate.was_skipped or
      cl ~= vstate.chunk_left or
      ct ~= vstate.chunk_top or
      cr ~= vstate.chunk_right or
      cb ~= vstate.chunk_bottom or
      surface_index ~= vstate.surface_index
    ) then
    vstate.was_skipped = false
    vstate.chunk_left, vstate.chunk_top, vstate.chunk_right, vstate.chunk_bottom = cl, ct, cr, cb
    vstate.surface_index = surface_index
    return true
  end

  return false
end

--- Rebuild the list of overlays currently in a player's viewport.
--- @param vstate PlayerViewportState
--- @param chunks table<number, table<number, LabOverlay[]>>
--- @param all_overlays_in_view LabOverlay[]
--- @param n_all_in_view number
--- @param n_visible_overlays number
--- @param current_tick number
--- @param mp_visited_tick table<LabOverlay[], number>|nil
--- @return integer n_all_in_view
--- @return integer n_visible_overlays
local function collect_overlays_in_player_view(vstate, chunks, all_overlays_in_view, n_all_in_view, n_visible_overlays, current_tick, mp_visited_tick)
  local player_index = vstate.player_index
  for cx = vstate.chunk_left, vstate.chunk_right do
    local col = chunks[cx]
    if col then
      for cy = vstate.chunk_top, vstate.chunk_bottom do
        local chunk = col[cy]
        local visited_tick = mp_visited_tick and chunk and mp_visited_tick[chunk]
        if chunk and (not visited_tick or visited_tick < current_tick) then
          if mp_visited_tick then
            mp_visited_tick[chunk] = current_tick
          end
          for j = 1, #chunk do
            local overlay = chunk[j]
            overlay.viewer_index = player_index
            n_all_in_view = n_all_in_view + 1
            all_overlays_in_view[n_all_in_view] = overlay
            if overlay.visible then
              n_visible_overlays = n_visible_overlays + 1
            end
          end
        end
      end
    end
  end
  return n_all_in_view, n_visible_overlays
end

--- Update the color epoch and function.
--- @param current_tick number
--- @param color_pattern_duration number
--- @param rng LuaRandomGenerator
--- @param color_function_index integer?
--- @return ColorFunction color_function
--- @return integer color_function_index
--- @return number phase_base
--- @return number phase_speed
--- @return number color_pattern_epoch_tick
local function update_color_epoch(current_tick, color_pattern_duration, rng, color_function_index)
  local epoch = current_tick / color_pattern_duration
  epoch = epoch - epoch % 1 -- floor

  local prev_index = color_function_index

  -- Reconstruct previous from epoch-1 only during initial call after load.
  if not prev_index and epoch > 0 then
    rng.re_seed((epoch - 1) % 10000 * 10000 + 12345)
    rng()                   -- skip phase_base
    random_phase_speed(rng) -- skip phase_speed
    local _
    _, prev_index = ColorFunctions.choose_random(nil, rng)
  end

  -- Deterministically derive current epoch state (O(1))
  rng.re_seed(epoch % 10000 * 10000 + 12345)
  local phase_base = rng() * 1000
  local phase_speed = random_phase_speed(rng)
  local color_function, next_index = ColorFunctions.choose_random(prev_index, rng)
  local color_pattern_epoch_tick = epoch * color_pattern_duration
  return color_function, next_index, phase_base, phase_speed, color_pattern_epoch_tick
end

--- No-op function
local function noop() end

--- Get a tick function and a state update request function.
---
--- The tick function performs three phases each tick:
---   1. Viewport update (every ~30 ticks, or on demand via request_viewport_update):
---      - Checks current_research for the player's force; refreshes colors when it changes.
---      - Updates player position and viewport chunk range.
---      - Rebuilds all_overlays_in_view from the chunk map when the viewport moves.
---   2. Incremental status scan (every tick):
---      - Checks entity.status for a small budget of overlays per tick, spread evenly across the ~30-tick cycle.
---      - Updates overlay.visible and n_visible_overlays when status changes.
---   3. Color update (every color_update_interval ticks):
---      - Updates colors of visible overlays using stride iteration.
---
--- The tick function should be refreshed after `render_overlays_for_all_labs()`.
---
--- @return fun(event: EventData.on_tick) tick_function
--- @return fun() request_viewport_update
--- @return fun() update_zoom_reach
--- @return fun(event: EventData.on_player_changed_position) update_player_position
function LabOverlayRenderer:get_tick_function()
  -- Because a tick function is critical for UPS (Updates Per Second), we should optimize it very tightly.
  --
  -- For optimization, as much as possible we should:
  -- * Avoid access to the same key on a table multiple times.
  -- * Avoid function calls. Make it inline.
  -- * Avoid creating a new object.
  -- * Avoid access to native objects provided by Factorio. C bridge call is expensive.

  local is_multiplayer = game.is_multiplayer()
  local connected_players = game.connected_players
  if not connected_players[1] then
    -- Return empty functions when no connected players (or before player creation in singleplayer mode)
    return noop, noop, noop, noop
  end
  local n_connected_players = #connected_players

  -- Capture chunk_map fields (mutated in-place by ChunkMap)
  local chunk_map = self.chunk_map
  local chunk_map_data = chunk_map.data

  -- Captured for inlined research color lookup in tick_function.
  local color_registry = self.color_registry

  --- Overlays currently in any player's view, including invisible overlays.
  local all_overlays_in_view = {} --- @type LabOverlay[]
  --- Cached `#all_overlays_in_view`.
  local n_all_in_view = 0
  --- Number of currently visible overlays.
  local n_visible_overlays = 0

  --- Force index to force research state including colors of ingredients
  --- @type table<number, ForceResearchState>
  local force_states = {}
  for _, force in pairs(game.forces) do
    force_states[force.index] = {
      force = force,
      current_research = nil,
      colors = nil,
      n_colors = 0,
    }
  end

  --- cached player.position keyed by connected_player index (not player.index). Only updated in multiplayer mode.
  --- @type MapPositionTuple[]
  local mp_player_positions = {}
  --- player.index to cached player.position for color functions. Values are shared with player_positions.
  --- @type table<integer, MapPositionTuple>
  local mp_player_index_to_position = {}
  --- connected_players index (not player.index) to viewport state.
  --- @type PlayerViewportState[]
  local player_viewport_states = {}
  for i = 1, n_connected_players do
    local player = connected_players[i]
    local pos = map_position_tuple(player.position)
    mp_player_positions[i] = pos
    mp_player_index_to_position[player.index] = pos
    local res = player.display_resolution
    player_viewport_states[i] = {
      viewport_width = res.width,
      viewport_height = res.height,
      chunk_left = 0,
      chunk_top = 0,
      chunk_right = 0,
      chunk_bottom = 0,
      surface_index = 0,
      was_skipped = true,
      player_index = player.index,
    }
  end

  local next_state_update_tick = 0    --- always force update at first tick
  local needs_viewport_rebuild = true --- true at first tick and when request_viewport_update() is called; triggers viewport rebuild and full status scan
  local status_cursor = 0
  local has_any_research = false

  -- Animation state
  local color_pattern_duration = Settings.color_pattern_duration
  local color_update_budget = Settings.color_update_budget
  local color_update_max_per_call = Settings.color_update_max_per_call
  local color_update_interval = 1
  local color_update_stride = 1

  -- Deterministically derived from game.tick and a constant seed.
  -- Re-calculated lazily inside tick_function when first called or at epoch boundaries.
  local rng = game.create_random_generator(0)
  local color_pattern_epoch_tick = 0
  local phase_base = 0
  local phase_speed = 0
  local color_function_index = nil --- @type integer|nil
  local color_function = nil       --- @type ColorFunction|nil
  local color = { 0, 0, 0 }

  -- === Singleplayer specific state ===

  local sp_player = connected_players[1]
  local sp_vstate = player_viewport_states[1]
  local sp_px, sp_py = mp_player_positions[1][1], mp_player_positions[1][2]
  local sp_fstate = force_states[sp_player.force_index]

  -- === Multiplayer specific state ===

  --- A weak key table of chunks for marking visited chunks in the current tick.
  --- @type table<LabOverlay[], number>|nil
  local mp_visited_tick = is_multiplayer and setmetatable({}, { __mode = "k" }) or nil

  if is_multiplayer then
    chunk_map:set_furthest_game_view_for_players(connected_players)
  else
    chunk_map:set_furthest_game_view(sp_player.zoom_limits.furthest_game_view, sp_vstate.viewport_width, sp_vstate.viewport_height)
  end

  --- @param event EventData.on_tick
  local function tick_function(event)
    local current_tick = event.tick
    local prev_n_visible_overlays = n_visible_overlays

    -- ========== Viewport update (every ~30 ticks, or forced by request_viewport_update) ==========
    if current_tick >= next_state_update_tick or needs_viewport_rebuild then
      next_state_update_tick = current_tick + 30 --[[$STATE_UPDATE_INTERVAL]]

      -- Update current_research and colors per force.
      local research_changed
      has_any_research, research_changed = update_all_force_research_states(force_states, color_registry)
      if not has_any_research and not research_changed then
        -- If all forces are idle, we can safely skip visibility and color updates. (all invisible)
        return
      end
      if research_changed then
        needs_viewport_rebuild = true
      end

      -- Update all players' viewport and check if any viewport changed
      local viewport_changed = false
      if is_multiplayer then
        for i = 1, n_connected_players do
          local player = connected_players[i]
          local pos = player.position
          local px, py = pos.x, pos.y
          local stored_pos = mp_player_positions[i]
          stored_pos[1] = px
          stored_pos[2] = py
          if update_player_viewport_state(player, player_viewport_states[i], px, py, chunk_map) then
            viewport_changed = true
          end
        end
      else
        local pos = sp_player.position
        sp_px, sp_py = pos.x, pos.y
        if update_player_viewport_state(sp_player, sp_vstate, sp_px, sp_py, chunk_map) then
          viewport_changed = true
        end
      end

      -- Rebuild all_overlays_in_view
      if viewport_changed or needs_viewport_rebuild then
        needs_viewport_rebuild = true -- ensure set when only viewport_changed triggered this
        local prev_n_all_in_view = n_all_in_view
        n_all_in_view = 0
        n_visible_overlays = 0

        for i = 1, n_connected_players do
          local vstate = player_viewport_states[i]
          if not vstate.was_skipped then
            local surface_chunks = chunk_map_data[vstate.surface_index]
            n_all_in_view, n_visible_overlays = collect_overlays_in_player_view(
              vstate, surface_chunks, all_overlays_in_view, n_all_in_view, n_visible_overlays, current_tick, mp_visited_tick)
          end
        end

        -- Clear trailing references from the previous tick's viewport scan.
        for i = n_all_in_view + 1, prev_n_all_in_view do
          if all_overlays_in_view[i] == nil then break end
          all_overlays_in_view[i] = nil
        end

        status_cursor = 0
      end

      -- Skip remaining tick work if no overlays are visible in singleplayer mode.
      if not is_multiplayer and sp_vstate.was_skipped then
        needs_viewport_rebuild = false
        return
      end
    end

    -- ========== Incremental status scan (every tick) ==========
    if n_all_in_view == 0 then
      needs_viewport_rebuild = false
    elseif has_any_research or needs_viewport_rebuild then
      -- If full scan is needed, iterate all overlays in the view. If not, use a budget that scales by n_all_in_view.
      local budget = needs_viewport_rebuild and n_all_in_view or ceil(n_all_in_view / 30 --[[$STATE_UPDATE_INTERVAL]])
      if budget < 1 then budget = 1 end
      needs_viewport_rebuild = false
      for _ = 1, budget do
        status_cursor = status_cursor + 1
        if status_cursor > n_all_in_view then status_cursor = 1 end
        local overlay = all_overlays_in_view[status_cursor]
        local entity = overlay.entity
        if not entity.valid then goto continue end

        local status = entity.status
        local force_index = overlay.force_index
        local force_state = force_states[force_index]
        local should_be_visible = (status == STATUS_WORKING or status == STATUS_LOW_POWER) and force_state ~= nil and force_state.current_research ~= nil
        if overlay.visible ~= should_be_visible then
          overlay.visible = should_be_visible
          overlay.animation.visible = should_be_visible
          if overlay.companion then
            overlay.companion.visible = should_be_visible
          end
          if should_be_visible then
            n_visible_overlays = n_visible_overlays + 1
          else
            n_visible_overlays = n_visible_overlays - 1
          end
        end
        ::continue::
      end
    end

    -- ========== Color update (every color_update_interval ticks) ==========
    if n_visible_overlays ~= prev_n_visible_overlays then
      local effective_budget = color_update_budget / n_connected_players
      local effective_max_per_call = color_update_max_per_call / n_connected_players
      color_update_stride = (n_visible_overlays > effective_max_per_call) and ceil(n_visible_overlays / effective_max_per_call) or 1
      if color_update_stride > 60 --[[$MAX_COLOR_UPDATE_STRIDE]] then color_update_stride = 60 --[[$MAX_COLOR_UPDATE_STRIDE]] end
      color_update_interval = max(1, ceil(n_visible_overlays / (effective_budget * color_update_stride)))
      if color_update_interval > 30 --[[$MAX_COLOR_UPDATE_INTERVAL]] then color_update_interval = 30 --[[$MAX_COLOR_UPDATE_INTERVAL]] end
    end

    if n_visible_overlays == 0 or not has_any_research then return end
    if not is_multiplayer and sp_player.render_mode == RENDER_MODE_CHART then return end
    if current_tick % color_update_interval ~= 0 then return end

    local elapsed_tick = current_tick - color_pattern_epoch_tick
    if not color_function or elapsed_tick >= color_pattern_duration then
      color_function, color_function_index, phase_base, phase_speed, color_pattern_epoch_tick =
        update_color_epoch(current_tick, color_pattern_duration, rng, color_function_index)
      elapsed_tick = current_tick - color_pattern_epoch_tick
    end

    local phase = phase_base + phase_speed * elapsed_tick
    local color_update_offset = (current_tick / color_update_interval) % color_update_stride + 1

    if is_multiplayer then
      local cached_force_index, cached_colors, cached_n_colors = 0, nil, 0
      local cached_viewer_index, cached_px, cached_py = 0, 0, 0
      for i = color_update_offset, n_all_in_view, color_update_stride do
        local overlay = all_overlays_in_view[i]
        if overlay.visible then
          local f_index = overlay.force_index
          if f_index ~= cached_force_index then
            cached_force_index = f_index
            local f_state = force_states[f_index]
            if f_state then
              cached_colors = f_state.colors
              cached_n_colors = f_state.n_colors
            else
              cached_colors = nil
              cached_n_colors = 0
            end
          end
          if cached_colors then
            local anim = overlay.animation
            if anim.valid then
              local viewer_index = overlay.viewer_index
              if cached_viewer_index ~= viewer_index then
                cached_viewer_index = viewer_index
                local vpos = mp_player_index_to_position[viewer_index]
                if vpos then
                  cached_px, cached_py = vpos[1], vpos[2]
                end
              end
              color_function(color, phase, cached_colors, cached_n_colors, cached_px, cached_py, overlay.x, overlay.y)
              anim.color = color
            end
          end
        end
      end
    else
      local cached_colors, cached_n_colors = sp_fstate.colors, sp_fstate.n_colors
      if cached_colors then
        for i = color_update_offset, n_all_in_view, color_update_stride do
          local overlay = all_overlays_in_view[i]
          if overlay.visible then
            local anim = overlay.animation
            if anim.valid then
              color_function(color, phase, cached_colors, cached_n_colors, sp_px, sp_py, overlay.x, overlay.y)
              anim.color = color
            end
          end
        end
      end
    end
  end

  local function request_viewport_update()
    needs_viewport_rebuild = true
  end

  local update_zoom_reach      --- @type fun()
  local update_player_position --- @type fun (event: EventData.on_player_changed_position)
  if is_multiplayer then
    update_zoom_reach = function ()
      chunk_map:set_furthest_game_view_for_players(connected_players)
    end

    --- @param event EventData.on_player_changed_position
    update_player_position = function (event)
      local p_index = event.player_index
      local player = game.players[p_index]
      if not player then return end

      local stored = mp_player_index_to_position[p_index]
      if stored then
        local pos = player.position
        stored[1], stored[2] = pos.x, pos.y
      end
    end
  else
    update_zoom_reach = function ()
      chunk_map:set_furthest_game_view(sp_player.zoom_limits.furthest_game_view, sp_vstate.viewport_width, sp_vstate.viewport_height)
    end

    update_player_position = function ()
      local pos = sp_player.position
      sp_px, sp_py = pos.x, pos.y
    end
  end

  return tick_function, request_viewport_update, update_zoom_reach, update_player_position
end

return LabOverlayRenderer
