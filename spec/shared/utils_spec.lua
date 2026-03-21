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
  describe("table_merge", function ()
    it("merges two tables", function ()
      local result = Utils.table_merge({ a = 1, b = 2 }, { c = 3 })
      assert.are.same({ a = 1, b = 2, c = 3 }, result)
    end)

    it("later values overwrite earlier ones for duplicate keys", function ()
      local result = Utils.table_merge({ a = 1, b = 2 }, { b = 99, c = 3 })
      assert.are.equal(1, result.a)
      assert.are.equal(99, result.b)
      assert.are.equal(3, result.c)
    end)

    it("returns a new table, not the original", function ()
      local t1 = { a = 1 }
      local t2 = { b = 2 }
      local result = Utils.table_merge(t1, t2)
      assert.are_not.equal(t1, result)
      assert.are_not.equal(t2, result)
    end)

    it("does not mutate the input tables", function ()
      local t1 = { a = 1 }
      local t2 = { b = 2 }
      Utils.table_merge(t1, t2)
      assert.is_nil(t1.b)
      assert.is_nil(t2.a)
    end)

    it("merges three or more tables", function ()
      local result = Utils.table_merge({ a = 1 }, { b = 2 }, { c = 3 })
      assert.are.same({ a = 1, b = 2, c = 3 }, result)
    end)

    it("returns an empty table when called with no arguments", function ()
      local result = Utils.table_merge()
      assert.are.same({}, result)
    end)

    it("shallow-copies values (does not deep-copy nested tables)", function ()
      local inner = { x = 10 }
      local result = Utils.table_merge({ inner = inner })
      assert.are.equal(inner, result.inner)
    end)

    it("skips nil values (nil overwrites are ignored)", function ()
      -- nil values cannot be stored in a table, so passing nil between tables is skipped
      local t1 = { a = 1 }
      local t2 = {}
      t2.a = nil -- explicit nil: pairs() will skip this key
      local result = Utils.table_merge(t1, t2)
      assert.are.equal(1, result.a)
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
end)
