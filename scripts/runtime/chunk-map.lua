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

local floor = math.floor

--- An entry stored in the chunk map for a single entity.
--- @class ChunkMapEntry
--- @field [1] number Surface index of the entity. (CE_SURFACE)
--- @field [2] number Chunk X coordinate of the entity. (CE_CX)
--- @field [3] number Chunk Y coordinate of the entity. (CE_CY)
--- @field [4] LabOverlay The lab overlay. (CE_OVERLAY)

-- ChunkMapEntry field indices
local CE_SURFACE = 1 -- Surface index
local CE_CX = 2      -- Chunk X coordinate
local CE_CY = 3      -- Chunk Y coordinate
local CE_OVERLAY = 4 -- LabOverlay

-- Index of the unit_number field in LabOverlay (OV_UNIT_NUM in lab-overlay-renderer.lua).
-- Used by swap-and-pop removal to identify which overlay to remove from a chunk.
local OVERLAY_UNIT_NUM = 6

local CHUNK_SIZE = 32
local INV_CHUNK_SIZE = 1 / CHUNK_SIZE

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
--- @param overlay LabOverlay The overlay to store for the entity.
function ChunkMap:insert(entity, overlay)
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
  chunk[#chunk + 1] = overlay

  self.entries[unit_number] = {
    surface_index, -- [CE_SURFACE]
    cx,            -- [CE_CX]
    cy,            -- [CE_CY]
    overlay,       -- [CE_OVERLAY]
  }
end

--- Remove an entity from the map.
---
--- @param unit_number number
function ChunkMap:remove(unit_number)
  local entry = self.entries[unit_number]
  if not entry then return end

  local data = self.data
  local surface_chunks = data[entry[CE_SURFACE]]
  if surface_chunks then
    local col = surface_chunks[entry[CE_CX]]
    if col then
      local chunk = col[entry[CE_CY]]
      if chunk then
        -- Linear scan + swap-and-pop (n is small per chunk).
        -- [A, B, C, D] → remove(B) → [A, D, C]
        local n = #chunk
        for i = 1, n do
          if chunk[i][OVERLAY_UNIT_NUM] == unit_number then
            if i ~= n then
              chunk[i] = chunk[n]
            end
            chunk[n] = nil
            break
          end
        end
        if not chunk[1] then
          col[entry[CE_CY]] = nil
          if not next(col) then
            surface_chunks[entry[CE_CX]] = nil
            if not next(surface_chunks) then
              data[entry[CE_SURFACE]] = nil
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

  if entry[CE_SURFACE] == new_surface_index and entry[CE_CX] == new_cx and entry[CE_CY] == new_cy then return end

  local overlay = entry[CE_OVERLAY]
  self:remove(unit_number)
  self:insert(entity, overlay)
end

--- Return the raw surface chunks table for direct iteration in hot paths.
---
--- @param surface_index number
--- @return table<number, table<number, LabOverlay[]>>|nil
function ChunkMap:get_surface_chunks(surface_index)
  return self.data[surface_index]
end

return ChunkMap
