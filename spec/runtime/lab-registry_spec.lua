local LabRegistry = require("scripts.runtime.lab-registry")

--- Set up mock mod_data for load_prototype_registrations tests.
--- @param registrations table<string, LabRegistration>|nil nil to remove mod_data
local function set_registered_labs(registrations)
  if registrations then
    _G.prototypes.mod_data[ "mks-dsl-registered-labs" --[[$REGISTERED_LABS_MOD_DATA_NAME]] ] = ({ data = registrations }) --[[@as LuaModData]]
  else
    _G.prototypes.mod_data[ "mks-dsl-registered-labs" --[[$REGISTERED_LABS_MOD_DATA_NAME]] ] = nil
  end
end

--- Set up mock excluded labs mod_data for load_prototype_registrations tests.
--- @param excluded table<string, boolean>|nil nil to remove mod_data
local function set_excluded_labs(excluded)
  if excluded then
    _G.prototypes.mod_data[ "mks-dsl-excluded-labs" --[[$EXCLUDED_LABS_MOD_DATA_NAME]] ] = ({ data = excluded }) --[[@as LuaModData]]
  else
    _G.prototypes.mod_data[ "mks-dsl-excluded-labs" --[[$EXCLUDED_LABS_MOD_DATA_NAME]] ] = nil
  end
end

describe("LabRegistry", function ()
  -- -------------------------------------------------------------------
  describe("new", function ()
    it("creates an instance with empty registrations", function ()
      local r = LabRegistry.new()
      assert.is_nil(r:get_registration("lab"))
      assert.is_nil(r:get_registration("biolab"))
    end)

    it("accepts a scale_overrides table", function ()
      local overrides = { ["my-lab"] = 3 }
      local r = LabRegistry.new(overrides)
      assert.are.equal(overrides, r.scale_overrides)
    end)

    it("defaults scale_overrides to an empty table when not provided", function ()
      local r = LabRegistry.new()
      assert.are.same({}, r.scale_overrides)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("register", function ()
    it("registers a new lab with default LabRegistration values", function ()
      local r = LabRegistry.new()
      r:register("my-lab")
      local registration = r:get_registration("my-lab")
      assert.is_not_nil(registration)       --- @cast registration -nil
      assert.is_nil(registration.animation) -- nil for default value
      assert.is_nil(registration.scale)
    end)

    it("registers a new lab with LabRegistration", function ()
      local r = LabRegistry.new()
      r:register("my-lab", { animation = "my-anim", scale = 2 })
      local registration = r:get_registration("my-lab")
      assert.is_not_nil(registration) --- @cast registration -nil
      assert.are.equal("my-anim", registration.animation)
      assert.are.equal(2, registration.scale)
    end)

    it("overwrites existing registration", function ()
      local r = LabRegistry.new()
      r:register("my-lab", { animation = "my-anim", scale = 2 })
      r:register("my-lab", { animation = "custom-anim", scale = 3 })
      local registration = r:get_registration("my-lab")
      assert.is_not_nil(registration) --- @cast registration -nil
      assert.are.equal("custom-anim", registration.animation)
      assert.are.equal(3, registration.scale)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("is_excluded", function ()
    it("returns false for an unregistered lab", function ()
      local r = LabRegistry.new()
      assert.is_false(r:is_excluded("my-lab"))
    end)

    it("returns true after load_prototype_registrations with excluded lab", function ()
      set_excluded_labs({ ["my-lab"] = true })
      local r = LabRegistry.new()
      r:load_prototype_registrations()
      assert.is_true(r:is_excluded("my-lab"))
    end)

    it("returns false for a non-excluded lab", function ()
      set_excluded_labs({ ["other-lab"] = true })
      local r = LabRegistry.new()
      r:load_prototype_registrations()
      assert.is_false(r:is_excluded("my-lab"))
    end)
  end)

  -- -------------------------------------------------------------------
  describe("set_scale", function ()
    it("updates scale for an existing lab", function ()
      local r = LabRegistry.new()
      r:register("my-lab", { scale = 1 })
      r:set_scale("my-lab", 2)
      local registration = r:get_registration("my-lab")
      assert.is_not_nil(registration) --- @cast registration -nil
      assert.are.equal(2, registration.scale)
    end)

    it("preserves animation when updating scale of an existing lab", function ()
      local r = LabRegistry.new()
      r:register("my-lab", { animation = "my-anim", scale = 1 })
      r:set_scale("my-lab", 3)
      assert.are.equal("my-anim", r:get_registration("my-lab").animation)
    end)

    it("auto-registers unknown lab with default overlay and given scale", function ()
      local r = LabRegistry.new()
      r:set_scale("new-lab", 4)
      local registration = r:get_registration("new-lab")
      assert.is_not_nil(registration)       --- @cast registration -nil
      assert.is_nil(registration.animation) -- nil for default value
      assert.are.equal(4, registration.scale)
    end)

    it("writes to the scale_overrides table", function ()
      local scale_overrides = {}
      local r = LabRegistry.new(scale_overrides)
      r:set_scale("my-lab", 3)
      assert.are.equal(3, scale_overrides["my-lab"])
    end)

    it("cancels exclusion for the lab", function ()
      set_excluded_labs({ ["my-lab"] = true })
      local r = LabRegistry.new()
      r:load_prototype_registrations()
      assert.is_true(r:is_excluded("my-lab"))
      r:set_scale("my-lab", 2)
      assert.is_false(r:is_excluded("my-lab"))
    end)
  end)

  -- -------------------------------------------------------------------
  describe("load_prototype_registrations", function ()
    before_each(function ()
      set_registered_labs(nil)
      set_excluded_labs(nil)
    end)

    it("does nothing when mod_data prototype is absent", function ()
      local r = LabRegistry.new()
      assert.no_error(function ()
        r:load_prototype_registrations()
      end)
      assert.is_nil(r:get_registration("lab"))
    end)

    it("loads lab registrations from mod_data", function ()
      set_registered_labs({ ["my-lab"] = { animation = "proto-anim", scale = 2 } })
      local r = LabRegistry.new()
      r:load_prototype_registrations()
      local registration = r:get_registration("my-lab")
      assert.is_not_nil(registration) --- @cast registration -nil
      assert.are.equal("proto-anim", registration.animation)
      assert.are.equal(2, registration.scale)
    end)

    it("loads multiple labs from mod_data", function ()
      set_registered_labs({
        ["lab-a"] = { animation = "anim-a", scale = 1 },
        ["lab-b"] = { animation = "anim-b", scale = 3 },
      })
      local r = LabRegistry.new()
      r:load_prototype_registrations()
      assert.are.equal("anim-a", r:get_registration("lab-a").animation)
      assert.are.equal("anim-b", r:get_registration("lab-b").animation)
    end)

    it("always overwrites existing registrations with prototype data", function ()
      set_registered_labs({ ["my-lab"] = { animation = "proto-anim", scale = 5 } })
      local r = LabRegistry.new()
      r:register("my-lab", { animation = "old-anim", scale = 1 })
      r:load_prototype_registrations()
      local registration = r:get_registration("my-lab")
      assert.is_not_nil(registration) --- @cast registration -nil
      assert.are.equal("proto-anim", registration.animation)
      assert.are.equal(5, registration.scale)
    end)

    it("replaces previously loaded registrations on re-load", function ()
      set_registered_labs({ ["lab-a"] = { animation = "anim-a", scale = 1 } })
      local r = LabRegistry.new()
      r:load_prototype_registrations()
      set_registered_labs({ ["lab-b"] = { animation = "anim-b", scale = 2 } })
      r:load_prototype_registrations()
      -- old lab is gone, new lab is present
      assert.is_nil(r:get_registration("lab-a"))
      assert.is_not_nil(r:get_registration("lab-b"))
    end)

    it("re-applies scale_overrides on top of prototype data", function ()
      set_registered_labs({ ["my-lab"] = { animation = "proto-anim", scale = 1 } })
      local scale_overrides = {}
      local r = LabRegistry.new(scale_overrides)
      r:set_scale("my-lab", 3)
      -- Simulate re-load: prototype data changes
      set_registered_labs({ ["my-lab"] = { animation = "new-proto-anim", scale = 2 } })
      r:load_prototype_registrations()
      local registration = r:get_registration("my-lab")
      assert.is_not_nil(registration) --- @cast registration -nil
      -- Animation is updated from prototype
      assert.are.equal("new-proto-anim", registration.animation)
      -- Scale override wins over new prototype value
      assert.are.equal(3, registration.scale)
    end)

    it("creates entry for scale_overrides of unregistered labs", function ()
      set_registered_labs({ ["lab-a"] = { animation = "anim-a", scale = 1 } })
      local r = LabRegistry.new()
      r:set_scale("unknown-lab", 4) -- not in prototype data
      r:load_prototype_registrations()
      local registration = r:get_registration("unknown-lab")
      assert.is_not_nil(registration) --- @cast registration -nil
      assert.is_nil(registration.animation)
      assert.are.equal(4, registration.scale)
    end)

    it("loads excluded labs from mod_data", function ()
      set_excluded_labs({ ["excluded-lab"] = true })
      local r = LabRegistry.new()
      r:load_prototype_registrations()
      assert.is_true(r:is_excluded("excluded-lab"))
    end)

    it("removes excluded labs from registered_labs", function ()
      set_registered_labs({ ["my-lab"] = { animation = "my-anim", scale = 1 } })
      set_excluded_labs({ ["my-lab"] = true })
      local r = LabRegistry.new()
      r:load_prototype_registrations()
      assert.is_nil(r:get_registration("my-lab"))
    end)

    it("skips excluded labs when re-applying scale_overrides", function ()
      set_registered_labs({ ["lab-a"] = { animation = "anim-a", scale = 1 } })
      set_excluded_labs({ ["excluded-lab"] = true })
      local r = LabRegistry.new()
      r.scale_overrides["excluded-lab"] = 3
      r:load_prototype_registrations()
      assert.is_nil(r:get_registration("excluded-lab"))
    end)

    it("clears excluded_labs when excluded labs mod-data is absent", function ()
      set_excluded_labs(nil)
      local r = LabRegistry.new()
      r.excluded_labs["my-lab"] = true
      r:load_prototype_registrations()
      assert.is_false(r:is_excluded("my-lab"))
    end)

    it("loads a copy of registrations (not a reference to the prototype data)", function ()
      set_registered_labs({ ["my-lab"] = { animation = "proto-anim", scale = 2 } })
      local r = LabRegistry.new()
      r:load_prototype_registrations()
      local proto_data = _G.prototypes.mod_data
        [ "mks-dsl-registered-labs" --[[$REGISTERED_LABS_MOD_DATA_NAME]] ].data
      assert.are_not.equal(proto_data["my-lab"], r:get_registration("my-lab"))
    end)
  end)

  -- -------------------------------------------------------------------
  describe("isolation between instances", function ()
    it("changes in one registry do not affect another", function ()
      local r1 = LabRegistry.new()
      local r2 = LabRegistry.new()
      r1:set_scale("my-lab", 3)
      r2:set_scale("my-lab", 5)
      assert.are_not.equal(5, r1:get_registration("my-lab").scale)
    end)
  end)
end)
