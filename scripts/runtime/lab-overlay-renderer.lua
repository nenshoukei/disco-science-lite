local Utils = require("scripts.shared.utils")
local ColorFunctions = require("scripts.runtime.color-functions")
local ChunkMap = require("scripts.runtime.chunk-map")
local PlayerViewTracker = require("scripts.runtime.player-view-tracker")

--- @class LabOverlayRenderer
local LabOverlayRenderer = {}
LabOverlayRenderer.__index = LabOverlayRenderer

local random = math.random
local max = math.max
local rendering_get_all_objects = rendering.get_all_objects
local draw_animation = rendering.draw_animation
local get_entity_rect = Utils.get_entity_rect
local STATUS_WORKING = defines.entity_status.working
local STATUS_LOW_POWER = defines.entity_status.low_power

--- @class (exact) LabOverlay
--- @field [1] LuaEntity        [OV_ENTITY]      Lab entity.
--- @field [2] LuaRenderObject  [OV_ANIMATION]   Render object for the overlay.
--- @field [3] number           [OV_X]           X coordinate.
--- @field [4] number           [OV_Y]           Y coordinate.
--- @field [5] MapPositionRect  [OV_RECT]        Rectangle boundaries of the entity.
--- @field [6] boolean          [OV_VISIBLE]     Last known visible state of the animation (cached, avoids repeated C bridge reads).
--- @field [7] number           [OV_UNIT_NUM]    Unit number of the lab entity (required by ChunkMap for swap-and-pop removal).
--- @field [8] number           [OV_FORCE_INDEX] Force index of the lab entity (cached, avoids C bridge read in tick function).

--- @class (exact) ForceState
--- @field [1] LuaTechnology|nil [FS_CURRENT_RESEARCH] Current researching technology.
--- @field [2] number[]|nil      [FS_COLORS]           Flattened colors array in format: `{ r, g, b, r, g, b... }`
--- @field [3] integer           [FS_N_COLORS]         Number of colors.
--- @field [4] number            [FS_PX]               First valid player's X position.
--- @field [5] number            [FS_PY]               First valid player's Y position.

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

    --- Tracks connected players' views. Key is player.index.
    --- @type table<number, PlayerViewTracker>
    player_trackers = {},

    --- Per-force state for the tick function. Key is force.index.
    --- @type table<number, ForceState>
    force_state = {},

    --- Flattened list of lab overlays currently in any player's view.
    --- @type LabOverlay[]
    visible_overlays = {},
  }
  return setmetatable(self, LabOverlayRenderer)
end

--- Render an overlay for a lab entity.
---
--- @param lab LuaEntity The lab entity.
--- @param existing_object LuaRenderObject? An existing render object to reuse (optional, used when rebuilding all). Must be valid.
--- @return LabOverlay|nil # The rendered overlay. `nil` if the lab is not target.
function LabOverlayRenderer:render_overlay_for_lab(lab, existing_object)
  if not lab.valid or lab.type ~= "lab" then return nil end

  local lab_unit_number = lab.unit_number
  if not lab_unit_number then return nil end

  local overlay_settings = self.lab_registry:get_overlay_settings(lab.name)
  if not overlay_settings and not settings.startup[ "mks-dsl-fallback-overlay-enabled" --[[$FALLBACK_OVERLAY_ENABLED_NAME]] ].value then
    return nil
  end

  local animation
  local scale
  if overlay_settings then
    -- If lab is registered but no overlay animation specified, use animation for the standard Factorio lab.
    animation = overlay_settings.animation or "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]]
    scale = overlay_settings.scale or 1
  else
    -- Fallback: use a generic glow animation for labs without a registered overlay sprite.
    -- Scale the overlay to fit the lab's tile size. The fallback sprite covers 2 tiles at scale=1.
    local prototype = lab.prototype
    animation = "mks-dsl-general-overlay" --[[$GENERAL_OVERLAY_ANIMATION_NAME]]
    scale = max(prototype.tile_width, prototype.tile_height) * 0.5
  end

  --- @type LuaRenderObject
  local render_object
  if existing_object then
    -- If existing rendering object given, just update it with the overlay settings.
    render_object = existing_object
    render_object.animation = animation
    render_object.x_scale = scale
    render_object.y_scale = scale
  else
    local is_randomized_flicker = not settings.global[ "mks-dsl-unison-flicker" --[[$UNISON_FLICKER_NAME]] ].value
    render_object = draw_animation({
      animation = animation,
      surface = lab.surface,
      target = lab,
      x_scale = scale,
      y_scale = scale,
      render_layer = "higher-object-under",
      visible = false,
      animation_offset = is_randomized_flicker and random() * 300 or 0,
    })
  end

  local lab_position = lab.position

  --- @type LabOverlay
  local new_overlay = {
    lab,                               -- OV_ENTITY
    render_object,                     -- OV_ANIMATION
    lab_position.x or lab_position[1], -- OV_X
    lab_position.y or lab_position[2], -- OV_Y
    get_entity_rect(lab),              -- OV_RECT
    render_object.visible,             -- OV_VISIBLE
    lab_unit_number,                   -- OV_UNIT_NUM
    lab.force_index,                   -- OV_FORCE_INDEX
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
  -- Collect all existing valid render objects from the mod.
  -- Index them by their target unit_number for fast lookup.
  local existing_render_objects = {}
  for _, object in ipairs(rendering_get_all_objects("disco-science-lite" --[[$MOD_NAME]])) do
    local target = object.target -- lab entity
    if target and target.valid then
      existing_render_objects[target.unit_number] = object
    else
      -- Destroy objects with no valid lab target.
      object.destroy()
    end
  end

  -- Reset data structures.
  self.overlays = {}
  self.chunk_map = ChunkMap.new()
  self.visible_overlays = {}
  self.force_state = {}

  local entity_filter = { type = "lab" }
  for _, surface in pairs(game.surfaces) do
    for _, lab in ipairs(surface.find_entities_filtered(entity_filter)) do
      local unit_number = lab.unit_number
      if unit_number then
        local existing_object = existing_render_objects[unit_number]

        -- Rebuild the overlay, reusing the existing render object if found.
        local new_overlay = self:render_overlay_for_lab(lab, existing_object)

        if new_overlay then
          -- Successfully reused or created. Remove from the map so it's not destroyed.
          existing_render_objects[unit_number] = nil
        end
      end
    end
  end

  -- Destroy any remaining render objects that were not reused.
  for _, object in pairs(existing_render_objects) do
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

  local animation = overlay[ 2 --[[$OV_ANIMATION]] ]
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
        local unit_number = overlay[ 7 --[[$OV_UNIT_NUM]] ]
        local animation = overlay[ 2 --[[$OV_ANIMATION]] ]
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

  overlay[ 5 --[[$OV_RECT]] ] = get_entity_rect(lab)

  local animation = overlay[ 2 --[[$OV_ANIMATION]] ]
  if animation.surface.index == lab.surface_index then
    -- Same surface: update animation target and chunk map if chunk changed.
    animation.target = lab
    self.chunk_map:move(lab)
  else
    -- The entity is teleported to another surface!
    animation.destroy()
    self:render_overlay_for_lab(lab)
  end
end

--- Remove the player tracker for the given player index.
---
--- @param player_index number
function LabOverlayRenderer:remove_player_tracker(player_index)
  self.player_trackers[player_index] = nil
end

--- Get a tracker update function to be called periodically or by events.
---
--- The returned function:
---   - Creates/updates player trackers for every connected players.
---   - Updates player positions of self.force_state from the first valid player for each force.
---
--- @return fun()
function LabOverlayRenderer:get_tracker_update_function()
  local player_trackers = self.player_trackers
  local force_state = self.force_state

  return function ()
    for force_index, force in pairs(game.forces) do
      local fs = force_state[force_index]
      for _, player in ipairs(force.connected_players) do
        local player_index = player.index
        local tracker = player_trackers[player_index]
        if not tracker then
          tracker = PlayerViewTracker.new()
          player_trackers[player_index] = tracker
        end
        tracker:update(player)

        -- Update force_state position from the first valid tracker for each force.
        if fs and tracker.view[ 1 --[[$PV_VALID]] ] then
          local pos = tracker.position
          fs[ 4 --[[$FS_PX]] ] = pos[1]
          fs[ 5 --[[$FS_PY]] ] = pos[2]
          fs = nil -- Only update for the first valid player.
        end
      end
    end
  end
end

--- Get a state update function to be called periodically (not every tick).
---
--- The returned function:
---   - Tracks current_research per force and updates force_state when it changes.
---   - Checks entity.status and updates overlay[OV_VISIBLE] and animation.visible.
---   - Rebuilds self.visible_overlays for the tick function to iterate.
---
--- Uses a generation counter to deduplicate overlays visible to multiple players.
---
--- @return fun()
function LabOverlayRenderer:get_state_update_function()
  local intensity = settings.global[ "mks-dsl-color-intensity" --[[$COLOR_INTENSITY_NAME]] ].value *
    0.01 --[[@as number]]
  local player_trackers = self.player_trackers
  local force_state = self.force_state
  local color_registry = self.color_registry
  local chunk_map = self.chunk_map
  local visible_overlays = self.visible_overlays

  -- A weak-key table to check if a chunk is updated in the current call. Key is a chunk (table) itself.
  -- Generation counter avoids clearing between calls: stale entries are ignored.
  --- @type table<table, integer>
  local visited_chunk = setmetatable({}, { __mode = "k" })
  local generation = 0

  return function ()
    generation = generation + 1
    local gen = generation

    -- Bind frequently used upvalues to local variables for performance
    -- luacheck: push ignore
    local visible_overlays = visible_overlays --- @diagnostic disable-line: redefined-local
    local STATUS_WORKING = STATUS_WORKING     --- @diagnostic disable-line: redefined-local
    local STATUS_LOW_POWER = STATUS_LOW_POWER --- @diagnostic disable-line: redefined-local
    -- luacheck: pop

    local chunk_map_data = chunk_map.data
    local count = 0
    for _, tracker in pairs(player_trackers) do
      local view = tracker.view
      if not view[ 1 --[[$PV_VALID]] ] then goto continue end

      local force = tracker.force --[[@as LuaForce]]
      local force_index = force.index
      local force_current_research = force.current_research

      -- Update force_state for this player's force.
      local fs = force_state[force_index]
      if not fs then
        local tracker_position = tracker.position
        fs = {
          nil,                 -- FS_CURRENT_RESEARCH
          nil,                 -- FS_COLORS
          0,                   -- FS_N_COLORS
          tracker_position[1], -- FS_PX
          tracker_position[2], -- FS_PY
        }
        force_state[force_index] = fs
      end
      if force_current_research ~= fs[ 1 --[[$FS_CURRENT_RESEARCH]] ] then
        fs[ 1 --[[$FS_CURRENT_RESEARCH]] ] = force_current_research
        if force_current_research then
          local colors = color_registry:get_colors_for_research(force_current_research, intensity)
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

          fs[ 2 --[[$FS_COLORS]] ] = flat_colors
          fs[ 3 --[[$FS_N_COLORS]] ] = n_colors
        else
          fs[ 2 --[[$FS_COLORS]] ] = nil
          fs[ 3 --[[$FS_N_COLORS]] ] = 0
        end
      end

      -- Iterate chunks in this player's view and build visible_overlays.
      local surface_chunks = chunk_map_data[view[ 2 --[[$PV_SURFACE]] ]]
      if surface_chunks then
        local chunk_left = view[ 3 --[[$PV_LEFT]] ]
        local chunk_top = view[ 4 --[[$PV_TOP]] ]
        local chunk_right = view[ 5 --[[$PV_RIGHT]] ]
        local chunk_bottom = view[ 6 --[[$PV_BOTTOM]] ]

        for cx = chunk_left, chunk_right do
          local col = surface_chunks[cx]
          if col then
            for cy = chunk_top, chunk_bottom do
              local chunk = col[cy]
              if chunk then
                -- Skip chunks already processed in this call (visible to multiple players).
                if visited_chunk[chunk] == gen then goto next_chunk end
                visited_chunk[chunk] = gen

                for i = 1, #chunk do
                  local overlay = chunk[i]
                  local status = overlay[ 1 --[[$OV_ENTITY]] ].status
                  local lab_fs = force_state[overlay[ 8 --[[$OV_FORCE_INDEX]] ]]
                  local colors = lab_fs and lab_fs[ 2 --[[$FS_COLORS]] ]
                  local is_visible = (
                    (status == STATUS_WORKING or status == STATUS_LOW_POWER) and
                    colors ~= nil
                  )
                  if overlay[ 6 --[[$OV_VISIBLE]] ] ~= is_visible then
                    overlay[ 6 --[[$OV_VISIBLE]] ] = is_visible
                    overlay[ 2 --[[$OV_ANIMATION]] ].visible = is_visible
                  end

                  if is_visible then
                    count = count + 1
                    visible_overlays[count] = overlay
                  end
                end

                ::next_chunk::
              end
            end
          end
        end
      end

      ::continue::
    end

    -- Clear trailing lab overlay references from the table to prevent memory leaks and GC issues.
    -- Setting elements to nil ensures that #visible_overlays accurately reflects the current count.
    for i = count + 1, #visible_overlays do
      if visible_overlays[i] == nil then break end
      visible_overlays[i] = nil
    end
  end
end

--- Get a tick function to be called by on_tick event.
---
--- The function updates colors of overlays in self.visible_overlays.
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
  local color_pattern_duration = global_settings[ "mks-dsl-color-pattern-duration" --[[$COLOR_PATTERN_DURATION_NAME]] ]
    .value --[[@as integer]]
  local lab_update_interval = global_settings[ "mks-dsl-lab-update-interval" --[[$LAB_UPDATE_INTERVAL_NAME]] ]
    .value --[[@as integer]]

  local visible_overlays = self.visible_overlays
  local force_state = self.force_state

  -- `phase` is a continuously drifting value passed to the color function.
  -- It drives animation by shifting the color cycle position over time.
  local phase = 0
  local phase_speed = ((random() * 5 + 3.5) % 6) - 3 -- [-3.0, -0.5) or [0.5, 3.0)
  local color_function, color_function_index = ColorFunctions.choose_random()
  local color_pattern_counter = 0
  local color = { 0, 0, 0 }
  local lab_update_offset = 1

  return function ()
    -- Return early when no overlays are visible (no player active, or no research in progress).
    -- `visible_overlays` is captured once at closure creation; it is mutated in-place by get_state_update_function().
    if #visible_overlays == 0 then return end

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

    -- Bind frequently used upvalues to local variables for performance
    -- luacheck: push ignore
    local visible_overlays = visible_overlays --- @diagnostic disable-line: redefined-local
    local force_state = force_state           --- @diagnostic disable-line: redefined-local
    local phase = phase                       --- @diagnostic disable-line: redefined-local
    local color_function = color_function     --- @diagnostic disable-line: redefined-local
    local color = color                       --- @diagnostic disable-line: redefined-local
    -- luacheck: pop

    -- Cache the last force's colors and player position to avoid repeated table lookups.
    -- In the common case (all labs on the same force), this avoids all but the first lookup.
    local last_force_index = -1
    local colors = nil
    local n_colors = 0
    local player_x = 0
    local player_y = 0

    -- Update colors of the visible overlays using stride iteration
    for i = lab_update_offset, #visible_overlays, lab_update_interval do
      local overlay = visible_overlays[i]
      local force_index = overlay[ 8 --[[$OV_FORCE_INDEX]] ]
      if force_index ~= last_force_index then
        last_force_index = force_index
        local fs = force_state[force_index]
        if fs then
          colors = fs[ 2 --[[$FS_COLORS]] ]
          n_colors = fs[ 3 --[[$FS_N_COLORS]] ]
          player_x = fs[ 4 --[[$FS_PX]] ]
          player_y = fs[ 5 --[[$FS_PY]] ]
        else
          colors = nil
        end
      end
      if colors then
        color_function(
          color, phase, colors, n_colors, player_x, player_y, overlay[ 3 --[[$OV_X]] ], overlay[ 4 --[[$OV_Y]] ]
        )
        overlay[ 2 --[[$OV_ANIMATION]] ].color = color
      end
    end
  end
end

return LabOverlayRenderer
