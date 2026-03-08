local consts = require("scripts.shared.consts")
local LabPrototypeRegistry = require("scripts.prototype.lab-prototype-registry")

describe("LabPrototypeRegistry", function ()
  before_each(function ()
    LabPrototypeRegistry.reset()
  end)

  -- -------------------------------------------------------------------
  describe("registered_labs", function ()
    it("contains default lab registration", function ()
      local settings = LabPrototypeRegistry.registered_labs["lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal(consts.LAB_OVERLAY_ANIMATION_NAME, settings.animation)
      assert.are.equal(1, settings.scale)
    end)

    it("contains default biolab registration", function ()
      local settings = LabPrototypeRegistry.registered_labs["biolab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal(consts.BIOLAB_OVERLAY_ANIMATION_NAME, settings.animation)
      assert.are.equal(1, settings.scale)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("register", function ()
    it("registers a new lab with settings", function ()
      LabPrototypeRegistry.register("my-lab", { animation = "my-anim", scale = 2 })
      local settings = LabPrototypeRegistry.registered_labs["my-lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("my-anim", settings.animation)
      assert.are.equal(2, settings.scale)
    end)

    it("registers a new lab with empty settings when nil is passed", function ()
      LabPrototypeRegistry.register("my-lab", nil)
      local settings = LabPrototypeRegistry.registered_labs["my-lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.is_nil(settings.animation)
      assert.is_nil(settings.scale)
    end)

    it("overwrites existing registration", function ()
      LabPrototypeRegistry.register("lab", { animation = "new-anim", scale = 3 })
      local settings = LabPrototypeRegistry.registered_labs["lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("new-anim", settings.animation)
      assert.are.equal(3, settings.scale)
    end)

    it("can register multiple labs independently", function ()
      LabPrototypeRegistry.register("lab-a", { animation = "anim-a", scale = 1 })
      LabPrototypeRegistry.register("lab-b", { animation = "anim-b", scale = 2 })
      assert.are.equal("anim-a", LabPrototypeRegistry.registered_labs["lab-a"].animation)
      assert.are.equal("anim-b", LabPrototypeRegistry.registered_labs["lab-b"].animation)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("reset", function ()
    it("removes custom registrations", function ()
      LabPrototypeRegistry.register("my-lab", { animation = "my-anim" })
      LabPrototypeRegistry.reset()
      assert.is_nil(LabPrototypeRegistry.registered_labs["my-lab"])
    end)

    it("restores default lab registration after reset", function ()
      LabPrototypeRegistry.register("lab", { animation = "overridden" })
      LabPrototypeRegistry.reset()
      local settings = LabPrototypeRegistry.registered_labs["lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal(consts.LAB_OVERLAY_ANIMATION_NAME, settings.animation)
    end)

    it("returns independent tables after each reset (no shared state)", function ()
      local before = LabPrototypeRegistry.registered_labs
      LabPrototypeRegistry.reset()
      assert.are_not.equal(before, LabPrototypeRegistry.registered_labs)
    end)
  end)
end)
