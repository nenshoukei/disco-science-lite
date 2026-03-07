--- A spatial map that groups LabOverlay entries into Factorio-style chunks.
---
--- Entries are bucketed by (surface_index, chunk_x, chunk_y). The map supports
--- O(1) insert and O(n) remove (n = entries per chunk, typically very small).
--- The raw chunk data is exposed for direct iteration in performance-critical
--- code (e.g. on_tick handlers).
---
--- @class ChunkMap
local ChunkMap = {}
ChunkMap.__index = ChunkMap

--- An entry stored in the chunk map for a single entity.
--- @class ChunkMapEntry
--- @field [1] number Surface index of the entity.
--- @field [2] number Chunk X coordinate of the entity.
--- @field [3] number Chunk Y coordinate of the entity.
--- @field [4] LabOverlay The overlay value.

if script then
  script.register_metatable("ChunkMap", ChunkMap)
end

local floor = math.floor

--- Size of each chunk in tiles.
local CHUNK_SIZE = 32
local INV_CHUNK_SIZE = 1 / CHUNK_SIZE
ChunkMap.CHUNK_SIZE = CHUNK_SIZE

--- Compute chunk coordinates for a world position.
---
--- @param pos_x number
--- @param pos_y number
--- @return number cx, number cy
function ChunkMap.position_to_chunk(pos_x, pos_y)
  return floor(pos_x * INV_CHUNK_SIZE), floor(pos_y * INV_CHUNK_SIZE)
end

--- Compute the chunk coordinate range that fully covers a world rect.
---
--- @param rect MapPositionRect
--- @return number chunk_left, number chunk_top, number chunk_right, number chunk_bottom
function ChunkMap.rect_to_chunk_range(rect)
  return floor(rect[1] * INV_CHUNK_SIZE), floor(rect[2] * INV_CHUNK_SIZE),
    floor(rect[3] * INV_CHUNK_SIZE), floor(rect[4] * INV_CHUNK_SIZE)
end

--- Constructor.
---
--- @return ChunkMap
function ChunkMap.new()
  --- @class ChunkMap
  local self = {
    --- Nested chunk data. `data[surface_index][cx][cy]` is an array of overlays.
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
--- If an entry for `entity.unit_number` already exists, it is removed first.
---
--- @param entity LuaEntity
--- @param value LabOverlay The overlay to store for the entity.
function ChunkMap:insert(entity, value)
  local unit_number = entity.unit_number
  if not unit_number then return end

  if self.entries[unit_number] then
    self:remove(unit_number)
  end

  local surface_index = entity.surface_index
  local position = entity.position
  local cx = floor((position.x or position[1]) * INV_CHUNK_SIZE)
  local cy = floor((position.y or position[2]) * INV_CHUNK_SIZE)

  local data = self.data
  local surface_chunks = data[surface_index]
  if not surface_chunks then
    surface_chunks = {}
    data[surface_index] = surface_chunks
  end
  local col = surface_chunks[cx]
  if not col then
    col = {}
    surface_chunks[cx] = col
  end
  local chunk = col[cy]
  if not chunk then
    chunk = {}
    col[cy] = chunk
  end
  chunk[#chunk + 1] = value

  self.entries[unit_number] = { surface_index, cx, cy, value }
end

--- Remove an entity from the map.
---
--- @param unit_number number
function ChunkMap:remove(unit_number)
  local entry = self.entries[unit_number]
  if not entry then return end

  local data = self.data
  local surface_chunks = data[entry[1]]
  if surface_chunks then
    local col = surface_chunks[entry[2]]
    if col then
      local chunk = col[entry[3]]
      if chunk then
        -- Linear scan + swap-and-pop (n is small per chunk).
        -- [A, B, C, D] → remove(B) → [A, D, C]
        local n = #chunk
        for i = 1, n do
          if chunk[i][6] == unit_number then
            if i ~= n then
              chunk[i] = chunk[n]
            end
            chunk[n] = nil
            break
          end
        end
        if not chunk[1] then
          col[entry[3]] = nil
          if not next(col) then
            surface_chunks[entry[2]] = nil
            if not next(surface_chunks) then
              data[entry[1]] = nil
            end
          end
        end
      end
    end
  end

  self.entries[unit_number] = nil
end

--- Move an entity to its current position.
---
--- The entity's `unit_number`, `surface_index`, and `position` are used as the new key.
--- Does nothing if the chunk coordinates have not changed.
---
--- @param entity LuaEntity
function ChunkMap:move(entity)
  local unit_number = entity.unit_number
  if not unit_number then return end

  local entry = self.entries[unit_number]
  if not entry then return end

  local new_surface_index = entity.surface_index
  local position = entity.position
  local new_cx = floor((position.x or position[1]) * INV_CHUNK_SIZE)
  local new_cy = floor((position.y or position[2]) * INV_CHUNK_SIZE)

  if entry[1] == new_surface_index and entry[2] == new_cx and entry[3] == new_cy then return end

  local value = entry[4]
  self:remove(unit_number)
  self:insert(entity, value)
end

--- Return the raw surface chunks table for direct iteration in hot paths.
---
--- @param surface_index number
--- @return table<number, table<number, LabOverlay[]>>|nil
function ChunkMap:get_surface_chunks(surface_index)
  return self.data[surface_index]
end

return ChunkMap
