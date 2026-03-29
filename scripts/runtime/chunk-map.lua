--- A spatial map that groups LabOverlay entries into Factorio-style chunks.
---
--- Entries are bucketed by (surface_index, chunk_x, chunk_y). The map supports O(1) insert and O(1) remove.
--- The raw chunk data is exposed for direct iteration in performance-critical code (e.g. on_tick handlers).
---
--- @class ChunkMap
local ChunkMap = {}
ChunkMap.__index = ChunkMap

--- An entry stored in the chunk map for a single entity.
--- @class (exact) ChunkMapEntry
--- @field surface_index number     Surface index of the entity.
--- @field chunk_x       number     Chunk X coordinate of the entity.
--- @field chunk_y       number     Chunk Y coordinate of the entity.
--- @field index         number     Index in the chunk.
--- @field overlay       LabOverlay The lab overlay.

--- Constructor.
---
--- @return ChunkMap
function ChunkMap.new()
  --- @class ChunkMap
  local self = {
    --- Nested chunk data. `data[surface_index][chunk_x][chunk_y]` is an array of overlays.
    --- @type table<number, table<number, table<number, LabOverlay[]>>>
    data = {},

    --- Entry lookup by unit_number.
    --- @type table<number, ChunkMapEntry>
    entries = {},

    --- Pre-expanded surface bounds per surface, keyed by surface_index.
    --- Each entry is [left, top, right, bottom] in tile coords, expanded by max_reach from the
    --- outermost lab positions. Used for fast player-outside-all-labs early-exit checks.
    --- nil for surfaces with no overlays, or before the first call to update_surface_bounds.
    --- @type table<number, MapPositionRect>
    surface_bounds = {},

    --- Surfaces whose bounds need recomputation, keyed by surface_index.
    --- Set to true by insert/remove; cleared by update_surface_bounds.
    --- @type table<number, boolean>
    surface_bounds_dirty = {},

    --- Cached furthest zoom rate (computed from ZoomSpecification). 0 if not set.
    --- @type number
    furthest_zoom = 0,

    --- Max viewport half-width in tiles at furthest_zoom + VIEW_RECT_MARGIN.
    --- @type number
    max_reach_x = 0,

    --- Max viewport half-height in tiles at furthest_zoom + VIEW_RECT_MARGIN.
    --- @type number
    max_reach_y = 0,
  }
  return setmetatable(self, ChunkMap)
end

--- Convert a ZoomSpecification to an actual zoom rate.
---
--- Supports Method 1 (fixed zoom field) and Method 2 (distance-based dynamic zoom).
--- For Method 2, the zoom is computed from the player's display dimensions and aspect ratio,
--- then capped by max_distance (defaults to 500) along the longer axis.
---
--- @param zoom_spec ZoomSpecification
--- @param width number Display width in pixels.
--- @param height number Display height in pixels.
--- @return number zoom
function ChunkMap.zoom_spec_to_zoom(zoom_spec, width, height)
  if zoom_spec.zoom then
    return zoom_spec.zoom
  end
  local distance = zoom_spec.distance --[[@as number]]
  local max_distance = zoom_spec.max_distance or 500
  local aspect = width / height
  local zoom_from_distance
  if aspect > 16 / 9 then
    -- Ultra-wide: distance * 9/16 tiles visible along height
    zoom_from_distance = height * 16 / (distance * 9 * 32 --[[$TILE_SIZE]])
  elseif aspect >= 1 then
    -- Normal wide (16:9 to 1:1): distance tiles visible along width
    zoom_from_distance = width / (distance * 32 --[[$TILE_SIZE]])
  elseif aspect >= 9 / 16 then
    -- Normal portrait (1:1 to 9:16): distance tiles visible along height
    zoom_from_distance = height / (distance * 32 --[[$TILE_SIZE]])
  else
    -- Ultra-portrait: distance * 9/16 tiles visible along height
    zoom_from_distance = height * 16 / (distance * 9 * 32 --[[$TILE_SIZE]])
  end
  -- max_distance constrains the furthest view to max_distance tiles along the longer axis.
  local longer_axis = width >= height and width or height
  local zoom_from_max = longer_axis / (max_distance * 32 --[[$TILE_SIZE]])
  -- Use the most restrictive (highest) zoom.
  return zoom_from_distance > zoom_from_max and zoom_from_distance or zoom_from_max
end

--- Update the furthest zoom from a ZoomSpecification, recomputing max_reach and marking
--- all surfaces dirty if the zoom changed.
---
--- @param zoom_spec ZoomSpecification
--- @param width number Display width in pixels.
--- @param height number Display height in pixels.
function ChunkMap:set_furthest_game_view(zoom_spec, width, height)
  local new_zoom = ChunkMap.zoom_spec_to_zoom(zoom_spec, width, height)
  if new_zoom == self.furthest_zoom then return end
  self.furthest_zoom = new_zoom
  self.max_reach_x = width  / (new_zoom * 64 --[[$TILE_SIZE * 2]]) + 6 --[[$VIEW_RECT_MARGIN]]
  self.max_reach_y = height / (new_zoom * 64 --[[$TILE_SIZE * 2]]) + 6 --[[$VIEW_RECT_MARGIN]]
  for surface_index in pairs(self.data) do
    self.surface_bounds_dirty[surface_index] = true
  end
end

--- Insert an entity into the map.
---
--- The entity's `unit_number`, `surface_index`, and `position` are used as the key.
---
--- If the entity already exists in the map, it just updates the existing one with new overlay values.
---
--- @param entity LuaEntity
--- @param overlay LabOverlay The overlay to store for the entity.
function ChunkMap:insert(entity, overlay)
  local unit_number = entity.unit_number
  if not unit_number then return end

  local surface_index = entity.surface_index
  local position = entity.position
  local chunk_x = (position.x or position[1]) / 32 --[[$CHUNK_SIZE]]
  local chunk_y = (position.y or position[2]) / 32 --[[$CHUNK_SIZE]]
  chunk_x = chunk_x - chunk_x % 1 -- equivalent to math.floor()
  chunk_y = chunk_y - chunk_y % 1

  local entries = self.entries
  local existing = entries[unit_number]
  if existing then
    if existing.surface_index == surface_index and existing.chunk_x == chunk_x and existing.chunk_y == chunk_y then
      -- Same keys, so just update the existing one.
      existing.overlay = overlay
      local index = existing.index
      self.data[surface_index][chunk_x][chunk_y][index] = overlay
      return
    end
    -- Keys are changed. Remove the existing one.
    self:remove(unit_number)
  end

  local data = self.data
  local surface_chunks = data[surface_index]
  if not surface_chunks then
    surface_chunks = {}
    data[surface_index] = surface_chunks
  end
  local col = surface_chunks[chunk_x]
  if not col then
    col = {}
    surface_chunks[chunk_x] = col
  end
  local chunk = col[chunk_y]
  if not chunk then
    chunk = {}
    col[chunk_y] = chunk
  end
  local index = #chunk + 1
  chunk[index] = overlay

  entries[unit_number] = {
    surface_index = surface_index,
    chunk_x = chunk_x,
    chunk_y = chunk_y,
    index = index,
    overlay = overlay,
  }

  self.surface_bounds_dirty[surface_index] = true
end

--- Get an overlay for the given unit_number.
---
--- @return LabOverlay|nil
function ChunkMap:get(unit_number)
  local entry = self.entries[unit_number]
  return entry and entry.overlay
end

--- Remove all data for the given surface, including bounds and dirty flags.
---
--- @param surface_index number
function ChunkMap:clear_surface(surface_index)
  self.data[surface_index] = nil
  self.surface_bounds[surface_index] = nil
  self.surface_bounds_dirty[surface_index] = nil
end

--- Remove an entity from the map.
---
--- @param unit_number number
function ChunkMap:remove(unit_number)
  local entry = self.entries[unit_number]
  if not entry then return end

  local surface_index = entry.surface_index
  self.surface_bounds_dirty[surface_index] = true
  local chunk_x = entry.chunk_x
  local chunk_y = entry.chunk_y
  local index = entry.index

  local data = self.data
  local surface_chunks = data[surface_index]
  if surface_chunks then
    local col = surface_chunks[chunk_x]
    if col then
      local chunk = col[chunk_y]
      if chunk then
        -- Swap-and-pop.
        -- [A, B, C, D] → remove(B) → [A, D, C]
        local last_index = #chunk
        if index ~= last_index then
          local last = chunk[last_index]
          chunk[index] = last
          self.entries[last.unit_number].index = index
        end
        chunk[last_index] = nil

        -- Clean up empty arrays.
        if not chunk[1] then
          col[chunk_y] = nil
          if not next(col) then
            surface_chunks[chunk_x] = nil
            if not next(surface_chunks) then
              self:clear_surface(surface_index)
            end
          end
        end
      end
    end
  end

  self.entries[unit_number] = nil
end

--- Recompute pre-expanded surface bounds for the given surface.
---
--- Sets `surface_bounds[surface_index]` to the lab area in tile coords expanded by max_reach_x/max_reach_y,
--- or nil if the surface has no overlays. Clears the dirty flag for this surface.
---
--- @param surface_index number
function ChunkMap:update_surface_bounds(surface_index)
  local reach_x = self.max_reach_x
  local reach_y = self.max_reach_y
  self.surface_bounds_dirty[surface_index] = nil

  local surface_chunks = self.data[surface_index]
  if not surface_chunks then
    self.surface_bounds[surface_index] = nil
    return
  end

  local min_cx = math.huge
  local max_cx = -math.huge
  local min_cy = math.huge
  local max_cy = -math.huge

  for cx, col in pairs(surface_chunks) do
    if cx < min_cx then min_cx = cx end
    if cx > max_cx then max_cx = cx end
    for cy in pairs(col) do
      if cy < min_cy then min_cy = cy end
      if cy > max_cy then max_cy = cy end
    end
  end

  local bounds = self.surface_bounds[surface_index]
  if not bounds then
    bounds = { 0, 0, 0, 0 } --[[@as MapPositionRect]]
    self.surface_bounds[surface_index] = bounds
  end
  bounds[1] = min_cx * 32 --[[$CHUNK_SIZE]] - reach_x       -- left
  bounds[2] = min_cy * 32 --[[$CHUNK_SIZE]] - reach_y       -- top
  bounds[3] = (max_cx + 1) * 32 --[[$CHUNK_SIZE]] + reach_x -- right
  bounds[4] = (max_cy + 1) * 32 --[[$CHUNK_SIZE]] + reach_y -- bottom
end

--- Recompute pre-expanded surface bounds for all surfaces.
function ChunkMap:update_all_surface_bounds()
  for surface_index in pairs(self.data) do
    self:update_surface_bounds(surface_index)
  end
  -- Clean up bounds and dirty flags for surfaces that no longer have data.
  for surface_index in pairs(self.surface_bounds_dirty) do
    self.surface_bounds_dirty[surface_index] = nil
    self.surface_bounds[surface_index] = nil
  end
end

return ChunkMap
