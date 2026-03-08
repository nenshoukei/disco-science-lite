local LabRegistry = require("scripts.runtime.lab-registry")
local consts = require("scripts.shared.consts")

describe("LabRegistry", function ()
  -- -------------------------------------------------------------------
  describe("new", function ()
    it("creates an instance with default lab registrations", function ()
      local r = LabRegistry.new()
      -- vanilla lab is always registered by default
      assert.is_not_nil(r:get("lab"))
    end)

    it("includes biolab by default", function ()
      local r = LabRegistry.new()
      assert.is_not_nil(r:get("biolab"))
    end)

    it("returns nil for unknown lab", function ()
      local r = LabRegistry.new()
      assert.is_nil(r:get("nonexistent-lab"))
    end)
  end)

  -- -------------------------------------------------------------------
  describe("add", function ()
    it("registers a new lab", function ()
      local r = LabRegistry.new()
      r:add("my-lab", { animation = "my-anim", scale = 2 })
      local reg = r:get("my-lab")
      assert.is_not_nil(reg) --- @cast reg -nil
      assert.are.equal("my-anim", reg.animation)
      assert.are.equal(2, reg.scale)
    end)

    it("overwrites an existing registration", function ()
      local r = LabRegistry.new()
      r:add("lab", { animation = "custom-anim", scale = 3 })
      local reg = r:get("lab")
      assert.is_not_nil(reg) --- @cast reg -nil
      assert.are.equal("custom-anim", reg.animation)
      assert.are.equal(3, reg.scale)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("set_scale", function ()
    it("updates scale for an existing lab", function ()
      local r = LabRegistry.new()
      r:set_scale("lab", 2)
      local reg = r:get("lab")
      assert.is_not_nil(reg) --- @cast reg -nil
      assert.are.equal(2, reg.scale)
    end)

    it("preserves animation when updating scale of an existing lab", function ()
      local r = LabRegistry.new()
      local original_animation = r:get("lab").animation
      r:set_scale("lab", 3)
      assert.are.equal(original_animation, r:get("lab").animation)
    end)

    it("auto-registers unknown lab with default overlay and given scale", function ()
      local r = LabRegistry.new()
      r:set_scale("new-lab", 4)
      local reg = r:get("new-lab")
      assert.is_not_nil(reg) --- @cast reg -nil
      assert.are.equal(consts.LAB_OVERLAY_ANIMATION_NAME, reg.animation)
      assert.are.equal(4, reg.scale)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("isolation between instances", function ()
    it("changes in one registry do not affect another", function ()
      local r1 = LabRegistry.new()
      local r2 = LabRegistry.new()
      r1:set_scale("lab", 5)
      assert.are_not.equal(5, r2:get("lab").scale)
    end)
  end)
end)
