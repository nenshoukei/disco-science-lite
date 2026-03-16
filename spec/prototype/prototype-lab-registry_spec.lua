local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

describe("PrototypeLabRegistry", function ()
  before_each(function ()
    PrototypeLabRegistry.reset()
  end)

  -- -------------------------------------------------------------------
  describe("registered_labs", function ()
    it("is empty when initialized", function ()
      assert.is_nil(next(PrototypeLabRegistry.registered_labs, nil))
    end)
  end)

  -- -------------------------------------------------------------------
  describe("register", function ()
    it("registers a new lab with settings", function ()
      PrototypeLabRegistry.register("my-lab", { animation = "my-anim", scale = 2 })
      local settings = PrototypeLabRegistry.registered_labs["my-lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("my-anim", settings.animation)
      assert.are.equal(2, settings.scale)
    end)

    it("registers a new lab with empty settings when nil is passed", function ()
      PrototypeLabRegistry.register("my-lab", nil)
      local settings = PrototypeLabRegistry.registered_labs["my-lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.is_nil(settings.animation)
      assert.is_nil(settings.scale)
    end)

    it("overwrites existing registration", function ()
      PrototypeLabRegistry.register("lab", { animation = "new-anim", scale = 3 })
      local settings = PrototypeLabRegistry.registered_labs["lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("new-anim", settings.animation)
      assert.are.equal(3, settings.scale)
    end)

    it("can register multiple labs independently", function ()
      PrototypeLabRegistry.register("lab-a", { animation = "anim-a", scale = 1 })
      PrototypeLabRegistry.register("lab-b", { animation = "anim-b", scale = 2 })
      assert.are.equal("anim-a", PrototypeLabRegistry.registered_labs["lab-a"].animation)
      assert.are.equal("anim-b", PrototypeLabRegistry.registered_labs["lab-b"].animation)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("reset", function ()
    it("clears registrations", function ()
      PrototypeLabRegistry.register("my-lab", { animation = "my-anim" })
      PrototypeLabRegistry.reset()
      assert.is_nil(next(PrototypeLabRegistry.registered_labs, nil))
    end)

    it("returns independent tables after each reset (no shared state)", function ()
      local before = PrototypeLabRegistry.registered_labs
      PrototypeLabRegistry.reset()
      assert.are_not.equal(before, PrototypeLabRegistry.registered_labs)
    end)
  end)
end)
