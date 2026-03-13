local ChunkMap = require("scripts.runtime.chunk-map")

--- Create a minimal LabOverlay-like value for ChunkMap tests.
--- ChunkMap.remove() checks overlay[OVERLAY_UNIT_NUM] for the unit_number.
--- @param unit_number number
--- @return LabOverlay
local function make_overlay(unit_number)
  return ({ unit_number = unit_number }) --[[@as LabOverlay]]
end

--- Create a mock LuaEntity.
--- @param unit_number number
--- @param surface_index number
--- @param x number
--- @param y number
--- @return LuaEntity
local function make_entity(unit_number, surface_index, x, y)
  return ({
    unit_number = unit_number,
    surface_index = surface_index,
    position = { x = x, y = y },
  }) --[[@as LuaEntity]]
end

describe("ChunkMap", function ()
  -- -------------------------------------------------------------------
  describe("new", function ()
    it("creates an empty map", function ()
      local m = ChunkMap.new()
      assert.are.same({}, m.data)
      assert.are.same({}, m.entries)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("insert", function ()
    it("adds an entry to entries and chunk data", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 0, 0)
      local v = make_overlay(1)
      m:insert(e, v)
      assert.is_not_nil(m.entries[1])
      local chunks = m.data[1]
      assert.is_not_nil(chunks)
    end)

    it("places the overlay in the correct chunk", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 16, 16)
      local v = make_overlay(1)
      m:insert(e, v)
      local chunks = m.data[1]
      assert.is_not_nil(chunks) --- @cast chunks -nil
      assert.is_not_nil(chunks[0])
      assert.is_not_nil(chunks[0][0])
      assert.are.equal(v, chunks[0][0][1])
    end)

    it("stores surface_index, cx, cy, overlay in the entry", function ()
      local m = ChunkMap.new()
      local e = make_entity(5, 10, 40, 80) -- chunk at (1, 2)
      local v = make_overlay(5)
      m:insert(e, v)
      local entry = m.entries[5]
      assert.are.equal(10, entry.surface_index)
      assert.are.equal(1, entry.chunk_x)
      assert.are.equal(2, entry.chunk_y)
      assert.are.equal(1, entry.index)
      assert.are.equal(v, entry.overlay)
    end)

    it("updates the entry if it has the same keys as before", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 0, 0)
      local v1 = make_overlay(1)
      local v2 = make_overlay(1)
      m:insert(e, v1)
      m:insert(e, v2)
      local chunks = m.data[1]
      assert.is_not_nil(chunks) --- @cast chunks -nil
      -- Only one entry should remain in the chunk
      assert.are.equal(1, #chunks[0][0])
      assert.are.equal(v2, chunks[0][0][1])
    end)

    it("re-inserts if chunk coordinates changed", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 0, 0) -- chunk (0,0)
      local v = make_overlay(1)
      m:insert(e, v)

      -- Change position to chunk (1,2)
      e.position = { x = 32, y = 64 }
      m:insert(e, v)

      -- Old chunk should be empty/nil
      assert.is_nil(m.data[1][0])
      -- New chunk should have the entry
      assert.are.equal(v, m.data[1][1][2][1])
      -- Entry should be updated
      local entry = m.entries[1]
      assert.are.equal(1, entry.chunk_x)
      assert.are.equal(2, entry.chunk_y)
    end)

    it("re-inserts if surface changed", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 0, 0) -- surface 1
      local v = make_overlay(1)
      m:insert(e, v)

      -- Change surface
      e.surface_index = 2
      m:insert(e, v)

      -- Old surface should be empty/nil
      assert.is_nil(m.data[1])
      -- New surface should have the entry
      assert.are.equal(v, m.data[2][0][0][1])
      -- Entry should be updated
      assert.are.equal(2, m.entries[1].surface_index)
    end)

    it("does nothing when entity has no unit_number", function ()
      local m = ChunkMap.new()
      local e = ({
        unit_number = nil,
        surface_index = 1,
        position = { x = 0, y = 0 },
      }) --[[@as LuaEntity]]
      m:insert(e, make_overlay(0))
      assert.are.same({}, m.data)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("remove", function ()
    it("removes the entry from entries and chunk data", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 0, 0)
      m:insert(e, make_overlay(1))
      m:remove(1)
      assert.is_nil(m.entries[1])
      assert.is_nil(m.data[1])
    end)

    it("does nothing for unknown unit_number", function ()
      local m = ChunkMap.new()
      m:remove(999) -- should not error
      assert.are.same({}, m.data)
    end)

    it("uses swap-and-pop, keeping remaining entries intact", function ()
      local m = ChunkMap.new()
      -- Insert A, B, C, D all in the same chunk (surface 1, position ~(0,0))
      local va = make_overlay(10)
      local vb = make_overlay(20)
      local vc = make_overlay(30)
      local vd = make_overlay(40)
      m:insert(make_entity(10, 1, 0, 0), va)
      m:insert(make_entity(20, 1, 0, 0), vb)
      m:insert(make_entity(30, 1, 0, 0), vc)
      m:insert(make_entity(40, 1, 0, 0), vd)

      m:remove(20) -- remove B

      -- Swap-and-popped: A, B, C, D → A, D, C
      local chunk = m.data[1][0][0]
      assert.are.equal(3, #chunk)
      assert.are.equal(va, chunk[1])
      assert.are.equal(vd, chunk[2])
      assert.are.equal(vc, chunk[3])

      -- All remaining unit numbers must still be present in entries
      assert.is_not_nil(m.entries[10])
      assert.is_nil(m.entries[20])
      assert.is_not_nil(m.entries[30])
      assert.is_not_nil(m.entries[40])

      -- .index should be updated
      assert.are.equal(1, m.entries[10].index)
      assert.are.equal(2, m.entries[40].index)
      assert.are.equal(3, m.entries[30].index)
    end)

    it("removes empty chunk column and surface table", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 0, 0)
      m:insert(e, make_overlay(1))
      m:remove(1)
      assert.is_nil(m.data[1]) -- entire surface entry cleaned up
    end)
  end)
end)
