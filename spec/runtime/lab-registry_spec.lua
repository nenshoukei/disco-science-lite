local LabRegistry = require("scripts.runtime.lab-registry")

describe("LabRegistry", function ()
  -- -------------------------------------------------------------------
  describe("new", function ()
    it("creates an instance with empty settings", function ()
      local r = LabRegistry.new()
      assert.is_nil(r:get_overlay_settings("lab"))
      assert.is_nil(r:get_overlay_settings("biolab"))
    end)
  end)

  -- -------------------------------------------------------------------
  describe("add", function ()
    it("registers a new lab with default overlay settings", function ()
      local r = LabRegistry.new()
      r:register("my-lab")
      local settings = r:get_overlay_settings("my-lab")
      assert.is_not_nil(settings)       --- @cast settings -nil
      assert.is_nil(settings.animation) -- nil for default value
      assert.is_nil(settings.scale)
    end)

    it("registers a new lab with overlay settings", function ()
      local r = LabRegistry.new()
      r:register("my-lab", { animation = "my-anim", scale = 2 })
      local settings = r:get_overlay_settings("my-lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("my-anim", settings.animation)
      assert.are.equal(2, settings.scale)
    end)

    it("overwrites existing settings", function ()
      local r = LabRegistry.new()
      r:register("my-lab", { animation = "my-anim", scale = 2 })
      r:register("my-lab", { animation = "custom-anim", scale = 3 })
      local settings = r:get_overlay_settings("my-lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("custom-anim", settings.animation)
      assert.are.equal(3, settings.scale)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("set_scale", function ()
    it("updates scale for an existing lab", function ()
      local r = LabRegistry.new()
      r:register("my-lab", { scale = 1 })
      r:set_scale("my-lab", 2)
      local settings = r:get_overlay_settings("my-lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal(2, settings.scale)
    end)

    it("preserves animation when updating scale of an existing lab", function ()
      local r = LabRegistry.new()
      r:register("my-lab", { animation = "my-anim", scale = 1 })
      r:set_scale("my-lab", 3)
      assert.are.equal("my-anim", r:get_overlay_settings("my-lab").animation)
    end)

    it("auto-registers unknown lab with default overlay and given scale", function ()
      local r = LabRegistry.new()
      r:set_scale("new-lab", 4)
      local settings = r:get_overlay_settings("new-lab")
      assert.is_not_nil(settings)       --- @cast settings -nil
      assert.is_nil(settings.animation) -- nil for default value
      assert.are.equal(4, settings.scale)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("isolation between instances", function ()
    it("changes in one registry do not affect another", function ()
      local r1 = LabRegistry.new()
      local r2 = LabRegistry.new()
      r1:set_scale("my-lab", 3)
      r2:set_scale("my-lab", 5)
      assert.are_not.equal(5, r1:get_overlay_settings("my-lab").scale)
    end)
  end)
end)
