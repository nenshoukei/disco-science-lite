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
  }
  return setmetatable(self, ChunkMap)
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
end

--- Get an overlay for the given unit_number.
---
--- @return LabOverlay|nil
function ChunkMap:get(unit_number)
  local entry = self.entries[unit_number]
  return entry and entry.overlay
end

--- Remove an entity from the map.
---
--- @param unit_number number
function ChunkMap:remove(unit_number)
  local entry = self.entries[unit_number]
  if not entry then return end

  local surface_index = entry.surface_index
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
              data[surface_index] = nil
            end
          end
        end
      end
    end
  end

  self.entries[unit_number] = nil
end

return ChunkMap
