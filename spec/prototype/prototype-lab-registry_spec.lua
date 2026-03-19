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
  describe("excluded_labs", function ()
    it("is empty when initialized", function ()
      assert.is_nil(next(PrototypeLabRegistry.excluded_labs, nil))
    end)
  end)

  -- -------------------------------------------------------------------
  describe("exclude", function ()
    it("adds lab to excluded_labs", function ()
      PrototypeLabRegistry.exclude("my-lab")
      assert.is_true(PrototypeLabRegistry.excluded_labs["my-lab"])
    end)

    it("removes lab from registered_labs", function ()
      PrototypeLabRegistry.register("my-lab", { animation = "my-anim" })
      PrototypeLabRegistry.exclude("my-lab")
      assert.is_nil(PrototypeLabRegistry.registered_labs["my-lab"])
    end)

    it("works on an unregistered lab", function ()
      assert.no_error(function ()
        PrototypeLabRegistry.exclude("unknown-lab")
      end)
      assert.is_true(PrototypeLabRegistry.excluded_labs["unknown-lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("register", function ()
    it("registers a new lab with LabRegistration", function ()
      PrototypeLabRegistry.register("my-lab", { animation = "my-anim", scale = 2 })
      local registration = PrototypeLabRegistry.registered_labs["my-lab"]
      assert.is_not_nil(registration) --- @cast registration -nil
      assert.are.equal("my-anim", registration.animation)
      assert.are.equal(2, registration.scale)
    end)

    it("registers a new lab with empty LabRegistration when nil is passed", function ()
      PrototypeLabRegistry.register("my-lab", nil)
      local registration = PrototypeLabRegistry.registered_labs["my-lab"]
      assert.is_not_nil(registration) --- @cast registration -nil
      assert.is_nil(registration.animation)
      assert.is_nil(registration.scale)
    end)

    it("overwrites existing registration", function ()
      PrototypeLabRegistry.register("lab", { animation = "new-anim", scale = 3 })
      local registration = PrototypeLabRegistry.registered_labs["lab"]
      assert.is_not_nil(registration) --- @cast registration -nil
      assert.are.equal("new-anim", registration.animation)
      assert.are.equal(3, registration.scale)
    end)

    it("removes exclusion when called on an excluded lab", function ()
      PrototypeLabRegistry.exclude("my-lab")
      PrototypeLabRegistry.register("my-lab", { animation = "my-anim" })
      assert.is_nil(PrototypeLabRegistry.excluded_labs["my-lab"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["my-lab"])
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

    it("clears excluded_labs", function ()
      PrototypeLabRegistry.exclude("my-lab")
      PrototypeLabRegistry.reset()
      assert.is_nil(next(PrototypeLabRegistry.excluded_labs, nil))
    end)

    it("returns independent tables after each reset (no shared state)", function ()
      local before_labs = PrototypeLabRegistry.registered_labs
      PrototypeLabRegistry.reset()
      assert.are_not.equal(before_labs, PrototypeLabRegistry.registered_labs)
    end)
  end)
end)
