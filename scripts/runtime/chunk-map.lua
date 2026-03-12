--- A spatial map that groups LabOverlay entries into Factorio-style chunks.
---
--- Entries are bucketed by (surface_index, chunk_x, chunk_y). The map supports O(1) insert and O(1) remove.
--- The raw chunk data is exposed for direct iteration in performance-critical code (e.g. on_tick handlers).
---
--- @class ChunkMap
local ChunkMap = {}
ChunkMap.__index = ChunkMap

local floor = math.floor

--- An entry stored in the chunk map for a single entity.
--- @class (exact) ChunkMapEntry
--- @field [1] number     [CE_SURFACE] Surface index of the entity.
--- @field [2] number     [CE_CX]      Chunk X coordinate of the entity.
--- @field [3] number     [CE_CY]      Chunk Y coordinate of the entity.
--- @field [4] number     [CE_INDEX]   Index in the chunk.
--- @field [5] LabOverlay [CE_OVERLAY] The lab overlay.

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
  local cx = floor((position.x or position[1]) * 0.03125 --[[$INV_CHUNK_SIZE]])
  local cy = floor((position.y or position[2]) * 0.03125 --[[$INV_CHUNK_SIZE]])

  local entries = self.entries
  local existing = entries[unit_number]
  if existing then
    if existing[ 1 --[[$CE_SURFACE]] ] == surface_index and existing[ 2 --[[$CE_CX]] ] == cx and existing[ 3 --[[$CE_CY]] ] == cy then
      -- Same keys, so just update the existing one.
      existing[ 5 --[[$CE_OVERLAY]] ] = overlay
      local index = existing[ 4 --[[$CE_INDEX]] ]
      self.data[surface_index][cx][cy][index] = overlay
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
  local index = #chunk + 1
  chunk[index] = overlay

  entries[unit_number] = {
    surface_index, -- CE_SURFACE
    cx,            -- CE_CX
    cy,            -- CE_CY
    index,         -- CE_INDEX
    overlay,       -- CE_OVERLAY
  }
end

--- Remove an entity from the map.
---
--- @param unit_number number
function ChunkMap:remove(unit_number)
  local entry = self.entries[unit_number]
  if not entry then return end

  local surface_index = entry[ 1 --[[$CE_SURFACE]] ]
  local cx = entry[ 2 --[[$CE_CX]] ]
  local cy = entry[ 3 --[[$CE_CY]] ]
  local index = entry[ 4 --[[$CE_INDEX]] ]

  local data = self.data
  local surface_chunks = data[surface_index]
  if surface_chunks then
    local col = surface_chunks[cx]
    if col then
      local chunk = col[cy]
      if chunk then
        -- Swap-and-pop.
        -- [A, B, C, D] → remove(B) → [A, D, C]
        local last_index = #chunk
        if index ~= last_index then
          local last = chunk[last_index]
          chunk[index] = last
          self.entries[last[ 7 --[[$OV_UNIT_NUM]] ]][ 4 --[[$CE_INDEX]] ] = index
        end
        chunk[last_index] = nil

        -- Clean up empty arrays.
        if not chunk[1] then
          col[cy] = nil
          if not next(col) then
            surface_chunks[cx] = nil
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
