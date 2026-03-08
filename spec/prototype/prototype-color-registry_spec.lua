local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

describe("PrototypeColorRegistry", function ()
  before_each(function ()
    PrototypeColorRegistry.reset()
  end)

  -- -------------------------------------------------------------------
  describe("registered_colors", function ()
    it("contains default automation-science-pack color", function ()
      local color = PrototypeColorRegistry.registered_colors["automation-science-pack"]
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.91, color[1])
      assert.are.equal(0.16, color[2])
      assert.are.equal(0.20, color[3])
    end)

    it("contains default logistic-science-pack color", function ()
      local color = PrototypeColorRegistry.registered_colors["logistic-science-pack"]
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.29, color[1])
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
      PrototypeColorRegistry.set("automation-science-pack", { 0.1, 0.2, 0.3 })
      local color = PrototypeColorRegistry.registered_colors["automation-science-pack"]
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
      local color = PrototypeColorRegistry.get("automation-science-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.91, color.r)
      assert.are.equal(0.16, color.g)
      assert.are.equal(0.20, color.b)
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
  describe("reset", function ()
    it("removes custom colors", function ()
      PrototypeColorRegistry.set("custom-pack", { 0.1, 0.2, 0.3 })
      PrototypeColorRegistry.reset()
      assert.is_nil(PrototypeColorRegistry.registered_colors["custom-pack"])
    end)

    it("restores default color after reset", function ()
      PrototypeColorRegistry.set("automation-science-pack", { 0, 0, 0 })
      PrototypeColorRegistry.reset()
      local color = PrototypeColorRegistry.registered_colors["automation-science-pack"]
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.91, color[1])
    end)

    it("returns independent tables after each reset (no shared state)", function ()
      local before = PrototypeColorRegistry.registered_colors
      PrototypeColorRegistry.reset()
      assert.are_not.equal(before, PrototypeColorRegistry.registered_colors)
    end)
  end)
end)
