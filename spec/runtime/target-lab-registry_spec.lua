local TargetLabRegistry = require("scripts.runtime.target-lab-registry")
local consts = require("scripts.shared.consts")

describe("TargetLabRegistry", function ()
  -- -------------------------------------------------------------------
  describe("new", function ()
    it("creates an instance with default target labs", function ()
      local r = TargetLabRegistry.new()
      -- vanilla lab is always registered by default
      assert.is_not_nil(r:get("lab"))
    end)

    it("includes biolab by default", function ()
      local r = TargetLabRegistry.new()
      assert.is_not_nil(r:get("biolab"))
    end)

    it("returns nil for unknown lab", function ()
      local r = TargetLabRegistry.new()
      assert.is_nil(r:get("nonexistent-lab"))
    end)
  end)

  -- -------------------------------------------------------------------
  describe("add", function ()
    it("registers a new lab type", function ()
      local r = TargetLabRegistry.new()
      r:add("my-lab", { animation = "my-anim", scale = 2 })
      local target = r:get("my-lab")
      assert.is_not_nil(target) --- @cast target -nil
      assert.are.equal("my-anim", target.animation)
      assert.are.equal(2, target.scale)
    end)

    it("overwrites an existing lab type", function ()
      local r = TargetLabRegistry.new()
      r:add("lab", { animation = "custom-anim", scale = 3 })
      local target = r:get("lab")
      assert.is_not_nil(target) --- @cast target -nil
      assert.are.equal("custom-anim", target.animation)
      assert.are.equal(3, target.scale)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("set_scale", function ()
    it("updates scale for an existing lab", function ()
      local r = TargetLabRegistry.new()
      r:set_scale("lab", 2)
      local target = r:get("lab")
      assert.is_not_nil(target) --- @cast target -nil
      assert.are.equal(2, target.scale)
    end)

    it("preserves animation when updating scale of an existing lab", function ()
      local r = TargetLabRegistry.new()
      local original_animation = r:get("lab").animation
      r:set_scale("lab", 3)
      assert.are.equal(original_animation, r:get("lab").animation)
    end)

    it("auto-registers unknown lab with default overlay and given scale", function ()
      local r = TargetLabRegistry.new()
      r:set_scale("new-lab", 4)
      local target = r:get("new-lab")
      assert.is_not_nil(target) --- @cast target -nil
      assert.are.equal(consts.LAB_OVERLAY_ANIMATION_NAME, target.animation)
      assert.are.equal(4, target.scale)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("isolation between instances", function ()
    it("changes in one registry do not affect another", function ()
      local r1 = TargetLabRegistry.new()
      local r2 = TargetLabRegistry.new()
      r1:set_scale("lab", 5)
      assert.are_not.equal(5, r2:get("lab").scale)
    end)
  end)
end)
