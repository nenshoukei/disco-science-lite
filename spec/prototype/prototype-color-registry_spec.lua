local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

describe("PrototypeColorRegistry", function ()
  before_each(function ()
    PrototypeColorRegistry.reset()
  end)

  -- -------------------------------------------------------------------
  describe("registered_colors", function ()
    it("is empty by default", function ()
      assert.is_nil(PrototypeColorRegistry.registered_colors["automation-science-pack"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("set", function ()
    it("sets a new color for a new ingredient", function ()
      PrototypeColorRegistry.set("custom-pack", { 0.1, 0.2, 0.3 })
      local color = PrototypeColorRegistry.registered_colors["custom-pack"]
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.1, color[1])
      assert.are.equal(0.2, color[2])
      assert.are.equal(0.3, color[3])
    end)

    it("overwrites an existing color", function ()
      PrototypeColorRegistry.set("custom-pack", { 0.5, 0.5, 0.5 })
      PrototypeColorRegistry.set("custom-pack", { 0.1, 0.2, 0.3 })
      local color = PrototypeColorRegistry.registered_colors["custom-pack"]
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.1, color[1])
    end)

    it("can set multiple colors independently", function ()
      PrototypeColorRegistry.set("pack-a", { 0.1, 0.0, 0.0 })
      PrototypeColorRegistry.set("pack-b", { 0.0, 0.2, 0.0 })
      assert.are.equal(0.1, PrototypeColorRegistry.registered_colors["pack-a"][1])
      assert.are.equal(0.2, PrototypeColorRegistry.registered_colors["pack-b"][2])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("get", function ()
    it("returns the color for a registered ingredient as ColorStruct", function ()
      PrototypeColorRegistry.set("custom-pack", { 0.1, 0.2, 0.3 })
      local color = PrototypeColorRegistry.get("custom-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.1, color.r)
      assert.are.equal(0.2, color.g)
      assert.are.equal(0.3, color.b)
    end)

    it("returns nil for an unregistered ingredient", function ()
      local color = PrototypeColorRegistry.get("unknown-pack")
      assert.is_nil(color)
    end)

    it("returns the updated color after set", function ()
      PrototypeColorRegistry.set("custom-pack", { 0.1, 0.2, 0.3 })
      local color = PrototypeColorRegistry.get("custom-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.1, color.r)
      assert.are.equal(0.2, color.g)
      assert.are.equal(0.3, color.b)
    end)

    it("returns nil after reset removes a custom color", function ()
      PrototypeColorRegistry.set("custom-pack", { 0.1, 0.2, 0.3 })
      PrototypeColorRegistry.reset()
      assert.is_nil(PrototypeColorRegistry.get("custom-pack"))
    end)
  end)

  -- -------------------------------------------------------------------
  describe("set_by_table", function ()
    it("sets new colors for new ingredients", function ()
      PrototypeColorRegistry.set_by_table({
        ["custom-pack-a"] = { 0.1, 0.2, 0.3 },
        ["custom-pack-b"] = { 0.4, 0.5, 0.6 },
      })
      local color_a = PrototypeColorRegistry.registered_colors["custom-pack-a"]
      local color_b = PrototypeColorRegistry.registered_colors["custom-pack-b"]
      assert.is_not_nil(color_a) --- @cast color_a -nil
      assert.are.equal(0.1, color_a[1])
      assert.are.equal(0.2, color_a[2])
      assert.are.equal(0.3, color_a[3])
      assert.is_not_nil(color_b) --- @cast color_b -nil
      assert.are.equal(0.4, color_b[1])
      assert.are.equal(0.5, color_b[2])
      assert.are.equal(0.6, color_b[3])
    end)

    it("overwrites existing colors", function ()
      PrototypeColorRegistry.set("custom-pack", { 0.9, 0.9, 0.9 })
      PrototypeColorRegistry.set_by_table({
        ["custom-pack"] = { 0.1, 0.2, 0.3 },
      })
      local color = PrototypeColorRegistry.registered_colors["custom-pack"]
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.1, color[1])
    end)

    it("does not affect colors not in the table", function ()
      PrototypeColorRegistry.set("pack-a", { 0.91, 0.16, 0.20 })
      PrototypeColorRegistry.set_by_table({
        ["custom-pack"] = { 0.1, 0.2, 0.3 },
      })
      local color = PrototypeColorRegistry.registered_colors["pack-a"]
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.91, color[1])
    end)

    it("does nothing for an empty table", function ()
      PrototypeColorRegistry.set("pack-a", { 0.91, 0.16, 0.20 })
      PrototypeColorRegistry.set_by_table({})
      local color = PrototypeColorRegistry.registered_colors["pack-a"]
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.91, color[1])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("reset", function ()
    it("removes custom colors", function ()
      PrototypeColorRegistry.set("custom-pack", { 0.1, 0.2, 0.3 })
      PrototypeColorRegistry.reset()
      assert.is_nil(PrototypeColorRegistry.registered_colors["custom-pack"])
    end)

    it("clears all colors", function ()
      PrototypeColorRegistry.set_by_table({
        ["pack-a"] = { 0.1, 0.2, 0.3 },
        ["pack-b"] = { 0.4, 0.5, 0.6 },
      })
      PrototypeColorRegistry.reset()
      assert.is_nil(PrototypeColorRegistry.registered_colors["pack-a"])
      assert.is_nil(PrototypeColorRegistry.registered_colors["pack-b"])
    end)

    it("returns independent tables after each reset (no shared state)", function ()
      local before = PrototypeColorRegistry.registered_colors
      PrototypeColorRegistry.reset()
      assert.are_not.equal(before, PrototypeColorRegistry.registered_colors)
    end)

    it("clears registered_prefixes", function ()
      PrototypeColorRegistry.add_prefix("compressed-")
      PrototypeColorRegistry.reset()
      assert.are.same({}, PrototypeColorRegistry.registered_prefixes)
    end)

    it("returns independent prefix tables after each reset (no shared state)", function ()
      local before = PrototypeColorRegistry.registered_prefixes
      PrototypeColorRegistry.reset()
      assert.are_not.equal(before, PrototypeColorRegistry.registered_prefixes)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("registered_prefixes", function ()
    it("is empty by default", function ()
      assert.are.same({}, PrototypeColorRegistry.registered_prefixes)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("add_prefix", function ()
    it("adds a prefix to registered_prefixes", function ()
      PrototypeColorRegistry.add_prefix("compressed-")
      assert.are.equal(1, #PrototypeColorRegistry.registered_prefixes)
      assert.are.equal("compressed-", PrototypeColorRegistry.registered_prefixes[1])
    end)

    it("can add multiple prefixes in order", function ()
      PrototypeColorRegistry.add_prefix("compressed-")
      PrototypeColorRegistry.add_prefix("expensive-")
      assert.are.equal(2, #PrototypeColorRegistry.registered_prefixes)
      assert.are.equal("compressed-", PrototypeColorRegistry.registered_prefixes[1])
      assert.are.equal("expensive-", PrototypeColorRegistry.registered_prefixes[2])
    end)
  end)
end)
