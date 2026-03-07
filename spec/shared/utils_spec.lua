local Utils = require("scripts.shared.utils")

describe("Utils", function ()
  -- -------------------------------------------------------------------
  describe("table_deep_copy", function ()
    it("returns an equal but distinct table", function ()
      local original = { a = 1, b = 2 }
      local copy = Utils.table_deep_copy(original)
      assert.are.same(original, copy)
      assert.are_not.equal(original, copy)
    end)

    it("deep-copies nested tables", function ()
      local original = { inner = { x = 10 } }
      local copy = Utils.table_deep_copy(original)
      assert.are.same(original, copy)
      assert.are_not.equal(original.inner, copy.inner)
    end)

    it("does not share nested table references", function ()
      local original = { inner = { x = 10 } }
      local copy = Utils.table_deep_copy(original)
      copy.inner.x = 99
      assert.are.equal(10, original.inner.x)
    end)

    it("copies arrays preserving order", function ()
      local original = { 10, 20, 30 }
      local copy = Utils.table_deep_copy(original)
      assert.are.same(original, copy)
    end)

    it("handles circular references without infinite loop", function ()
      local original = {}
      original.self = original
      local copy = Utils.table_deep_copy(original)
      assert.are.equal(copy, copy.self)
    end)

    it("preserves non-table values unchanged", function ()
      local original = { n = 42, s = "hello", b = true }
      local copy = Utils.table_deep_copy(original)
      assert.are.equal(42, copy.n)
      assert.are.equal("hello", copy.s)
      assert.are.equal(true, copy.b)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("color_tuple", function ()
    it("converts indexed color to tuple", function ()
      local t = Utils.color_tuple({ 0.1, 0.2, 0.3 })
      assert.are.equal(0.1, t[1])
      assert.are.equal(0.2, t[2])
      assert.are.equal(0.3, t[3])
    end)

    it("converts named color (r,g,b) to tuple", function ()
      local t = Utils.color_tuple({ r = 0.4, g = 0.5, b = 0.6 })
      assert.are.equal(0.4, t[1])
      assert.are.equal(0.5, t[2])
      assert.are.equal(0.6, t[3])
    end)

    it("prefers indexed keys over named keys", function ()
      local t = Utils.color_tuple({ 0.7, 0.8, 0.9, r = 0.0, g = 0.0, b = 0.0 })
      assert.are.equal(0.7, t[1])
      assert.are.equal(0.8, t[2])
      assert.are.equal(0.9, t[3])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("color_struct", function ()
    it("converts indexed color to struct", function ()
      local s = Utils.color_struct({ 0.1, 0.2, 0.3 })
      assert.are.equal(0.1, s.r)
      assert.are.equal(0.2, s.g)
      assert.are.equal(0.3, s.b)
    end)

    it("converts named color (r,g,b) to struct", function ()
      local s = Utils.color_struct({ r = 0.4, g = 0.5, b = 0.6 })
      assert.are.equal(0.4, s.r)
      assert.are.equal(0.5, s.g)
      assert.are.equal(0.6, s.b)
    end)

    it("prefers indexed keys over named keys", function ()
      local s = Utils.color_struct({ 0.7, 0.8, 0.9, r = 0.0, g = 0.0, b = 0.0 })
      assert.are.equal(0.7, s.r)
      assert.are.equal(0.8, s.g)
      assert.are.equal(0.9, s.b)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("map_position_tuple", function ()
    it("converts indexed position to tuple", function ()
      local t = Utils.map_position_tuple({ 3, 7 })
      assert.are.equal(3, t[1])
      assert.are.equal(7, t[2])
    end)

    it("converts named position (x,y) to tuple", function ()
      local t = Utils.map_position_tuple({ x = 10, y = 20 })
      assert.are.equal(10, t[1])
      assert.are.equal(20, t[2])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("map_position_struct", function ()
    it("converts indexed position to struct", function ()
      local s = Utils.map_position_struct({ 3, 7 })
      assert.are.equal(3, s.x)
      assert.are.equal(7, s.y)
    end)

    it("converts named position (x,y) to struct", function ()
      local s = Utils.map_position_struct({ x = 10, y = 20 })
      assert.are.equal(10, s.x)
      assert.are.equal(20, s.y)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("position_to_chunk", function ()
    it("maps origin to chunk (0,0)", function ()
      local cx, cy = Utils.position_to_chunk(0, 0)
      assert.are.equal(0, cx)
      assert.are.equal(0, cy)
    end)

    it("maps position inside first chunk to (0,0)", function ()
      local cx, cy = Utils.position_to_chunk(31.9, 31.9)
      assert.are.equal(0, cx)
      assert.are.equal(0, cy)
    end)

    it("maps position at exactly CHUNK_SIZE boundary to (1,1)", function ()
      local cx, cy = Utils.position_to_chunk(32, 32)
      assert.are.equal(1, cx)
      assert.are.equal(1, cy)
    end)

    it("handles negative positions", function ()
      local cx, cy = Utils.position_to_chunk(-1, -1)
      assert.are.equal(-1, cx)
      assert.are.equal(-1, cy)
    end)

    it("handles negative position at exact negative boundary", function ()
      local cx, cy = Utils.position_to_chunk(-32, -32)
      assert.are.equal(-1, cx)
      assert.are.equal(-1, cy)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("rect_to_chunk_range", function ()
    it("returns correct chunk range for a rect within a single chunk", function ()
      local l, t, r, b = Utils.rect_to_chunk_range({ 0, 0, 10, 10 })
      assert.are.equal(0, l)
      assert.are.equal(0, t)
      assert.are.equal(0, r)
      assert.are.equal(0, b)
    end)

    it("returns correct chunk range spanning multiple chunks", function ()
      local l, t, r, b = Utils.rect_to_chunk_range({ 0, 0, 64, 64 })
      assert.are.equal(0, l)
      assert.are.equal(0, t)
      assert.are.equal(2, r)
      assert.are.equal(2, b)
    end)

    it("handles negative coordinates", function ()
      local l, t, r, b = Utils.rect_to_chunk_range({ -32, -32, 0, 0 })
      assert.are.equal(-1, l)
      assert.are.equal(-1, t)
      assert.are.equal(0, r)
      assert.are.equal(0, b)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("get_entity_rect", function ()
    local function make_entity(px, py, w, h)
      return ({
        position = { x = px, y = py },
        tile_width = w,
        tile_height = h,
      }) --[[@as LuaEntity]]
    end

    it("returns rect as {left, top, right, bottom}", function ()
      local rect = Utils.get_entity_rect(make_entity(2, 4, 3, 5))
      assert.are.equal(2, rect[1])
      assert.are.equal(4, rect[2])
      assert.are.equal(5, rect[3])
      assert.are.equal(9, rect[4])
    end)

    it("works with indexed position", function ()
      local entity = ({
        position = { 6, 8 },
        tile_width = 2,
        tile_height = 2,
      }) --[[@as LuaEntity]]
      local rect = Utils.get_entity_rect(entity)
      assert.are.equal(6, rect[1])
      assert.are.equal(8, rect[2])
      assert.are.equal(8, rect[3])
      assert.are.equal(10, rect[4])
    end)

    it("handles negative positions", function ()
      local rect = Utils.get_entity_rect(make_entity(-10, -5, 4, 4))
      assert.are.equal(-10, rect[1])
      assert.are.equal(-5, rect[2])
      assert.are.equal(-6, rect[3])
      assert.are.equal(-1, rect[4])
    end)
  end)
end)
