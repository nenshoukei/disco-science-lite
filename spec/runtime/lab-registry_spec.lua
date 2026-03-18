local LabRegistry = require("scripts.runtime.lab-registry")

--- Set up mock mod_data for load_prototype_settings tests.
--- @param settings table<string, LabOverlaySettings>|nil nil to remove mod_data
local function set_mod_data(settings)
  if settings then
    _G.prototypes.mod_data[ "mks-dsl-lab-overlay-settings" --[[$LAB_OVERLAY_SETTINGS_MOD_DATA_NAME]] ] = ({ data = settings }) --[[@as LuaModData]]
  else
    _G.prototypes.mod_data[ "mks-dsl-lab-overlay-settings" --[[$LAB_OVERLAY_SETTINGS_MOD_DATA_NAME]] ] = nil
  end
end

--- Set up mock excluded labs mod_data for load_prototype_settings tests.
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
    it("creates an instance with empty settings", function ()
      local r = LabRegistry.new()
      assert.is_nil(r:get_overlay_settings("lab"))
      assert.is_nil(r:get_overlay_settings("biolab"))
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
  describe("is_excluded", function ()
    it("returns false for an unregistered lab", function ()
      local r = LabRegistry.new()
      assert.is_false(r:is_excluded("my-lab"))
    end)

    it("returns true after load_prototype_settings with excluded lab", function ()
      set_excluded_labs({ ["my-lab"] = true })
      local r = LabRegistry.new()
      r:load_prototype_settings()
      assert.is_true(r:is_excluded("my-lab"))
    end)

    it("returns false for a non-excluded lab", function ()
      set_excluded_labs({ ["other-lab"] = true })
      local r = LabRegistry.new()
      r:load_prototype_settings()
      assert.is_false(r:is_excluded("my-lab"))
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

    it("writes to the scale_overrides table", function ()
      local scale_overrides = {}
      local r = LabRegistry.new(scale_overrides)
      r:set_scale("my-lab", 3)
      assert.are.equal(3, scale_overrides["my-lab"])
    end)

    it("cancels exclusion for the lab", function ()
      set_excluded_labs({ ["my-lab"] = true })
      local r = LabRegistry.new()
      r:load_prototype_settings()
      assert.is_true(r:is_excluded("my-lab"))
      r:set_scale("my-lab", 2)
      assert.is_false(r:is_excluded("my-lab"))
    end)
  end)

  -- -------------------------------------------------------------------
  describe("load_prototype_settings", function ()
    before_each(function ()
      set_mod_data(nil)
      set_excluded_labs(nil)
    end)

    it("does nothing when mod_data prototype is absent", function ()
      local r = LabRegistry.new()
      assert.no_error(function ()
        r:load_prototype_settings()
      end)
      assert.is_nil(r:get_overlay_settings("lab"))
    end)

    it("loads settings from mod_data", function ()
      set_mod_data({ ["my-lab"] = { animation = "proto-anim", scale = 2 } })
      local r = LabRegistry.new()
      r:load_prototype_settings()
      local settings = r:get_overlay_settings("my-lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("proto-anim", settings.animation)
      assert.are.equal(2, settings.scale)
    end)

    it("loads multiple labs from mod_data", function ()
      set_mod_data({
        ["lab-a"] = { animation = "anim-a", scale = 1 },
        ["lab-b"] = { animation = "anim-b", scale = 3 },
      })
      local r = LabRegistry.new()
      r:load_prototype_settings()
      assert.are.equal("anim-a", r:get_overlay_settings("lab-a").animation)
      assert.are.equal("anim-b", r:get_overlay_settings("lab-b").animation)
    end)

    it("always overwrites existing settings with prototype data", function ()
      set_mod_data({ ["my-lab"] = { animation = "proto-anim", scale = 5 } })
      local r = LabRegistry.new()
      r:register("my-lab", { animation = "old-anim", scale = 1 })
      r:load_prototype_settings()
      local settings = r:get_overlay_settings("my-lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("proto-anim", settings.animation)
      assert.are.equal(5, settings.scale)
    end)

    it("replaces previously loaded settings on re-load", function ()
      set_mod_data({ ["lab-a"] = { animation = "anim-a", scale = 1 } })
      local r = LabRegistry.new()
      r:load_prototype_settings()
      set_mod_data({ ["lab-b"] = { animation = "anim-b", scale = 2 } })
      r:load_prototype_settings()
      -- old lab is gone, new lab is present
      assert.is_nil(r:get_overlay_settings("lab-a"))
      assert.is_not_nil(r:get_overlay_settings("lab-b"))
    end)

    it("re-applies scale_overrides on top of prototype data", function ()
      set_mod_data({ ["my-lab"] = { animation = "proto-anim", scale = 1 } })
      local scale_overrides = {}
      local r = LabRegistry.new(scale_overrides)
      r:set_scale("my-lab", 3)
      -- Simulate re-load: prototype data changes
      set_mod_data({ ["my-lab"] = { animation = "new-proto-anim", scale = 2 } })
      r:load_prototype_settings()
      local settings = r:get_overlay_settings("my-lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      -- Animation is updated from prototype
      assert.are.equal("new-proto-anim", settings.animation)
      -- Scale override wins over new prototype value
      assert.are.equal(3, settings.scale)
    end)

    it("creates entry for scale_overrides of unregistered labs", function ()
      set_mod_data({ ["lab-a"] = { animation = "anim-a", scale = 1 } })
      local r = LabRegistry.new()
      r:set_scale("unknown-lab", 4) -- not in prototype data
      r:load_prototype_settings()
      local settings = r:get_overlay_settings("unknown-lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.is_nil(settings.animation)
      assert.are.equal(4, settings.scale)
    end)

    it("loads excluded labs from mod_data", function ()
      set_excluded_labs({ ["excluded-lab"] = true })
      local r = LabRegistry.new()
      r:load_prototype_settings()
      assert.is_true(r:is_excluded("excluded-lab"))
    end)

    it("removes excluded labs from overlay_settings", function ()
      set_mod_data({ ["my-lab"] = { animation = "my-anim", scale = 1 } })
      set_excluded_labs({ ["my-lab"] = true })
      local r = LabRegistry.new()
      r:load_prototype_settings()
      assert.is_nil(r:get_overlay_settings("my-lab"))
    end)

    it("skips excluded labs when re-applying scale_overrides", function ()
      set_mod_data({ ["lab-a"] = { animation = "anim-a", scale = 1 } })
      set_excluded_labs({ ["excluded-lab"] = true })
      local r = LabRegistry.new()
      r.scale_overrides["excluded-lab"] = 3
      r:load_prototype_settings()
      assert.is_nil(r:get_overlay_settings("excluded-lab"))
    end)

    it("clears excluded_labs when excluded labs mod-data is absent", function ()
      set_excluded_labs(nil)
      local r = LabRegistry.new()
      r.excluded_labs["my-lab"] = true
      r:load_prototype_settings()
      assert.is_false(r:is_excluded("my-lab"))
    end)

    it("loads a copy of settings (not a reference to the prototype data)", function ()
      set_mod_data({ ["my-lab"] = { animation = "proto-anim", scale = 2 } })
      local r = LabRegistry.new()
      r:load_prototype_settings()
      local proto_data = _G.prototypes.mod_data
        [ "mks-dsl-lab-overlay-settings" --[[$LAB_OVERLAY_SETTINGS_MOD_DATA_NAME]] ].data
      assert.are_not.equal(proto_data["my-lab"], r:get_overlay_settings("my-lab"))
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
