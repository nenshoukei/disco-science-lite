local ChunkMap = require("scripts.runtime.chunk-map")

--- Create a minimal LabOverlay-like value for ChunkMap tests.
--- ChunkMap.remove() checks overlay[OVERLAY_UNIT_NUM] (= [6]) for the unit_number.
--- @param unit_number number
--- @return LabOverlay
local function make_overlay(unit_number)
  return ({ nil, nil, nil, nil, nil, unit_number }) --[[@as LabOverlay]]
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
      local chunks = m:get_surface_chunks(1)
      assert.is_not_nil(chunks)
    end)

    it("places the overlay in the correct chunk", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 16, 16)
      local v = make_overlay(1)
      m:insert(e, v)
      local chunks = m:get_surface_chunks(1)
      assert.is_not_nil(chunks) --- @cast chunks -nil
      assert.is_not_nil(chunks[0])
      assert.is_not_nil(chunks[0][0])
      assert.are.equal(v, chunks[0][0][1])
    end)

    it("stores surface_index, cx, cy, overlay in the entry", function ()
      local m = ChunkMap.new()
      local e = make_entity(5, 2, 0, 0)
      local v = make_overlay(5)
      m:insert(e, v)
      local entry = m.entries[5]
      assert.are.equal(2, entry[1]) -- surface_index
      assert.are.equal(0, entry[2]) -- cx
      assert.are.equal(0, entry[3]) -- cy
      assert.are.equal(v, entry[4]) -- overlay
    end)

    it("re-inserts (remove then add) if unit_number already exists", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 0, 0)
      local v1 = make_overlay(1)
      local v2 = make_overlay(1)
      m:insert(e, v1)
      m:insert(e, v2)
      local chunks = m:get_surface_chunks(1)
      assert.is_not_nil(chunks) --- @cast chunks -nil
      -- Only one entry should remain in the chunk
      assert.are.equal(1, #chunks[0][0])
      assert.are.equal(v2, chunks[0][0][1])
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

      local chunk = m:get_surface_chunks(1)[0][0]
      assert.are.equal(3, #chunk)

      -- All remaining unit numbers must still be present in entries
      assert.is_not_nil(m.entries[10])
      assert.is_nil(m.entries[20])
      assert.is_not_nil(m.entries[30])
      assert.is_not_nil(m.entries[40])
    end)

    it("removes empty chunk column and surface table", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 0, 0)
      m:insert(e, make_overlay(1))
      m:remove(1)
      assert.is_nil(m.data[1]) -- entire surface entry cleaned up
    end)
  end)

  -- -------------------------------------------------------------------
  describe("move", function ()
    it("does nothing when unit_number is not in the map", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 0, 0)
      m:move(e) -- should not error
      assert.are.same({}, m.data)
    end)

    it("does nothing when chunk coordinates have not changed", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 5, 5)
      local v = make_overlay(1)
      m:insert(e, v)
      m:move(e)
      -- Entry must still be present unchanged
      assert.is_not_nil(m.entries[1])
      local chunk = m:get_surface_chunks(1)[0][0]
      assert.are.equal(1, #chunk)
    end)

    it("moves the overlay to the new chunk when position changes", function ()
      local m = ChunkMap.new()
      local v = make_overlay(1)
      local e_old = make_entity(1, 1, 5, 5) -- chunk (0,0)
      m:insert(e_old, v)

      local e_new = make_entity(1, 1, 50, 50) -- chunk (1,1)
      m:move(e_new)

      local old_chunks = m:get_surface_chunks(1)
      -- Old chunk (0,0) should be gone
      assert.is_nil(old_chunks and old_chunks[0])
      -- New chunk (1,1) should contain the overlay
      assert.is_not_nil(old_chunks and old_chunks[1] and old_chunks[1][1])
    end)

    it("does nothing when entity has no unit_number", function ()
      local m = ChunkMap.new()
      local e = ({ unit_number = nil, surface_index = 1, position = { x = 0, y = 0 } }) --[[@as LuaEntity]]
      m:move(e) -- should not error
    end)
  end)

  -- -------------------------------------------------------------------
  describe("get_surface_chunks", function ()
    it("returns nil for unknown surface", function ()
      local m = ChunkMap.new()
      assert.is_nil(m:get_surface_chunks(99))
    end)

    it("returns the chunk table after insert", function ()
      local m = ChunkMap.new()
      m:insert(make_entity(1, 3, 0, 0), make_overlay(1))
      assert.is_not_nil(m:get_surface_chunks(3))
    end)

    it("returns nil after the only entity on that surface is removed", function ()
      local m = ChunkMap.new()
      m:insert(make_entity(1, 3, 0, 0), make_overlay(1))
      m:remove(1)
      assert.is_nil(m:get_surface_chunks(3))
    end)
  end)
end)
