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
    --- @type table<number, PlayerViewTracker|nil>
    player_trackers = {},

    --- Per-force state for the tick function. Key is force.index.
    --- @type table<number, ForceState|nil>
    force_state = {},

    --- Flattened list of lab overlays currently in any player's view.
    --- @type LabOverlay[]
    visible_overlays = {},

    --- Whether the fallback overlay is enabled.
    is_fallback_enabled = true,

    --- Whether the overlay animation flickers in unison.
    is_unison_flicker = false,

    --- Color intensity. [0, 1]
    color_intensity = 1.0,

    --- Color function duration in ticks.
    color_pattern_duration = 180,

    --- Maximum number of labs to update per tick. Controls automatic interval scaling.
    max_updates_per_tick = 500,

    --- Current dynamic interval (throttled based on load).
    current_interval = 1,
  }
  self = setmetatable(self, LabOverlayRenderer)
  self:load_settings()
  return self
end

--- Load settings from the `settings` global variable.
function LabOverlayRenderer:load_settings()
  local startup = settings.startup
  local global = settings.global
  local old_unison_flicker = self.is_unison_flicker
  local old_color_intensity = self.color_intensity

  self.is_fallback_enabled =
    startup[ "mks-dsl-fallback-overlay-enabled" --[[$FALLBACK_OVERLAY_ENABLED_NAME]] ].value --[[@as boolean]]
  self.is_unison_flicker =
    global[ "mks-dsl-unison-flicker" --[[$UNISON_FLICKER_NAME]] ].value --[[@as boolean]]
  self.color_intensity =
    global[ "mks-dsl-color-intensity" --[[$COLOR_INTENSITY_NAME]] ].value * 0.01
  self.color_pattern_duration =
    global[ "mks-dsl-color-pattern-duration" --[[$COLOR_PATTERN_DURATION_NAME]] ].value --[[@as integer]]
  self.max_updates_per_tick =
    global[ "mks-dsl-max-updates-per-tick" --[[$MAX_UPDATES_PER_TICK_NAME]] ].value --[[@as integer]]

  -- Since `game` is not available for `on_load`, this guard avoids updates on game state in `on_load` handler.
  if game then
    if old_unison_flicker ~= self.is_unison_flicker then
      self:reset_all_overlays_animation_offset()
    end
    if old_color_intensity ~= self.color_intensity then
      self:update_all_forces_current_research()
    end
  end
end

--- Render an overlay for a lab entity.
---
--- @param lab LuaEntity The lab entity. Must be valid.
--- @param existing_object LuaRenderObject? An existing render object to reuse (optional, used when rebuilding all). Must be valid.
--- @return LabOverlay|nil # The rendered overlay. `nil` if the lab is not target.
function LabOverlayRenderer:render_overlay_for_lab(lab, existing_object)
  local lab_unit_number = lab.unit_number
  if not lab_unit_number then return nil end

  local overlay_settings = self.lab_registry:get_overlay_settings(lab.name)
  if not overlay_settings and not self.is_fallback_enabled then
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
      animation_offset = self.is_unison_flicker and 0 or random() * 300,
    })
  end

  local lab_position = lab.position
  local lab_x = lab_position.x or lab_position[1]
  local lab_y = lab_position.y or lab_position[2]
  local lab_rect = { lab_x, lab_y, lab_x + lab.tile_width, lab_y + lab.tile_height }

  --- @type LabOverlay
  local new_overlay = {
    lab,                   -- OV_ENTITY
    render_object,         -- OV_ANIMATION
    lab_x,                 -- OV_X
    lab_y,                 -- OV_Y
    lab_rect,              -- OV_RECT
    render_object.visible, -- OV_VISIBLE
    lab_unit_number,       -- OV_UNIT_NUM
    lab.force_index,       -- OV_FORCE_INDEX
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
  local existing_objects = {}
  local all_objects = rendering_get_all_objects("disco-science-lite" --[[$MOD_NAME]])
  for i = 1, #all_objects do
    local object = all_objects[i]
    local entity = object.target.entity
    if entity and entity.valid and entity.unit_number then
      existing_objects[entity.unit_number] = object
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
    local entities = surface.find_entities_filtered(entity_filter)
    for i = 1, #entities do
      local lab = entities[i]
      local unit_number = lab.unit_number
      if unit_number then
        local existing_object = existing_objects[unit_number]

        -- Rebuild the overlay, reusing the existing render object if found.
        local new_overlay = self:render_overlay_for_lab(lab, existing_object)

        if new_overlay then
          -- Successfully reused or created. Remove from the map so it's not destroyed.
          existing_objects[unit_number] = nil
        end
      end
    end
  end

  -- Destroy any remaining render objects that were not reused.
  for _, object in pairs(existing_objects) do
    object.destroy()
  end
end

--- Reset animation_offset of all overlays for updated is_unison_flicker.
function LabOverlayRenderer:reset_all_overlays_animation_offset()
  local is_unison_flicker = self.is_unison_flicker
  local all_objects = rendering_get_all_objects("disco-science-lite" --[[$MOD_NAME]])
  for i = 1, #all_objects do
    local object = all_objects[i]
    object.animation_offset = is_unison_flicker and 0 or random() * 300
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
--- @param lab LuaEntity The lab entity. Must be valid.
function LabOverlayRenderer:update_lab_position(lab)
  local lab_unit_number = lab.unit_number
  if not lab_unit_number then return end

  local overlay = self.overlays[lab_unit_number]
  if not overlay then return end

  local lab_position = lab.position
  local lab_x = lab_position.x or lab_position[1]
  local lab_y = lab_position.y or lab_position[2]
  overlay[ 3 --[[$OV_X]] ] = lab_x
  overlay[ 4 --[[$OV_Y]] ] = lab_y
  overlay[ 5 --[[$OV_RECT]] ] = { lab_x, lab_y, lab_x + lab.tile_width, lab_y + lab.tile_height }

  local animation = overlay[ 2 --[[$OV_ANIMATION]] ]
  if animation.surface.index == lab.surface_index then
    -- Same surface: update animation target and chunk map if chunk changed.
    animation.target = lab
    self.chunk_map:insert(lab, overlay) -- updates the existing entry
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

--- Get a position update function to be called every 10 ticks or by events.
---
--- The returned function:
---   - Creates player trackers for newly connected players.
---   - Updates player positions of self.force_state from the first valid player for each force.
---
--- @return fun()
function LabOverlayRenderer:get_position_update_function()
  local player_trackers = self.player_trackers
  local force_state = self.force_state

  return function ()
    for _, force in pairs(game.forces) do
      local connected_players = force.connected_players
      local n_connected_players = #connected_players
      if n_connected_players > 0 then
        local fs = force_state[force.index]
        for i = 1, n_connected_players do
          local player = connected_players[i]
          local player_index = player.index
          local tracker = player_trackers[player_index]
          if not tracker then
            tracker = PlayerViewTracker.new(player)
            tracker:update()
            player_trackers[player_index] = tracker
          end

          -- Update force_state position from the first valid player for each force.
          if fs and tracker.view[ 1 --[[$PV_VALID]] ] then
            local pos = player.position
            fs[ 4 --[[$FS_PX]] ] = pos.x or pos[1]
            fs[ 5 --[[$FS_PY]] ] = pos.y or pos[2]
            fs = nil -- Only update for the first valid player.
          end
        end
      end
    end
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
  fs[ 1 --[[$FS_CURRENT_RESEARCH]] ] = force_current_research

  if force_current_research then
    local colors = self.color_registry:get_colors_for_research(force_current_research, self.color_intensity)
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

--- Get a state update function to be called every 30 ticks.
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
  local player_trackers = self.player_trackers
  local force_state = self.force_state
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
      tracker:update()
      local view = tracker.view
      if not view[ 1 --[[$PV_VALID]] ] then goto continue end

      local player = tracker.player
      local force = player.force --[[@as LuaForce]]
      local force_index = force.index

      -- Update force_state for this player's force.
      local fs = force_state[force_index]
      if not fs then
        local pos = player.position
        fs = {
          nil,             -- FS_CURRENT_RESEARCH
          nil,             -- FS_COLORS
          0,               -- FS_N_COLORS
          pos.x or pos[1], -- FS_PX
          pos.y or pos[2], -- FS_PY
        }
        force_state[force_index] = fs
      end
      if force.current_research ~= fs[ 1 --[[$FS_CURRENT_RESEARCH]] ] then
        -- Update current research in the force_state
        self:update_force_current_research(force)
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

    -- Update dynamic interval based on the number of visible overlays.
    -- Automatically extend the interval if there are more labs than the per-tick budget.
    local max_updates = self.max_updates_per_tick
    local interval = (count > max_updates) and math.ceil(count / max_updates) or 1
    if interval > 60 then interval = 60 end
    self.current_interval = interval
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

  local visible_overlays = self.visible_overlays
  local force_state = self.force_state
  local color_pattern_duration = self.color_pattern_duration

  -- `phase` is a continuously drifting value passed to the color function.
  -- It drives animation by shifting the color cycle position over time.
  local phase = 0
  local phase_speed = (((random() * 5 + 3.5) % 6) - 3) * 0.025 -- { [-3.0, -0.5) or [0.5, 3.0) } / 40
  local color_function, color_function_index = ColorFunctions.choose_random()
  local color_pattern_counter = 0
  local color = { 0, 0, 0 }
  local lab_update_offset = 1

  return function ()
    -- Return early when no overlays are visible (no player active, or no research in progress).
    -- `visible_overlays` is captured once at closure creation; it is mutated in-place by get_state_update_function().
    if #visible_overlays == 0 then return end

    local current_interval = self.current_interval
    phase = phase + phase_speed

    -- Switch color function periodically. Also update phase_speed.
    color_pattern_counter = color_pattern_counter + 1
    if color_pattern_counter >= color_pattern_duration then
      color_pattern_counter = 0
      color_function, color_function_index = ColorFunctions.choose_random(color_function_index)
      phase_speed = (((random() * 5 + 3.5) % 6) - 3) * 0.025
    end

    lab_update_offset = lab_update_offset + 1
    if lab_update_offset > current_interval then lab_update_offset = 1 end

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
    for i = lab_update_offset, #visible_overlays, current_interval do
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
