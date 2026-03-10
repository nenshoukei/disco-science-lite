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
  describe("load_prototype_settings", function ()
    before_each(function ()
      set_mod_data(nil)
    end)

    it("does nothing when mod_data prototype is absent", function ()
      local r = LabRegistry.new()
      assert.no_error(function ()
        r:load_prototype_settings(true)
      end)
      assert.is_nil(r:get_overlay_settings("lab"))
    end)

    it("loads settings from mod_data when overwrites is true", function ()
      set_mod_data({ ["my-lab"] = { animation = "proto-anim", scale = 2 } })
      local r = LabRegistry.new()
      r:load_prototype_settings(true)
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
      r:load_prototype_settings(true)
      assert.are.equal("anim-a", r:get_overlay_settings("lab-a").animation)
      assert.are.equal("anim-b", r:get_overlay_settings("lab-b").animation)
    end)

    it("overwrites existing settings when overwrites is true", function ()
      set_mod_data({ ["my-lab"] = { animation = "proto-anim", scale = 5 } })
      local r = LabRegistry.new()
      r:register("my-lab", { animation = "runtime-anim", scale = 1 })
      r:load_prototype_settings(true)
      local settings = r:get_overlay_settings("my-lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("proto-anim", settings.animation)
      assert.are.equal(5, settings.scale)
    end)

    it("does not overwrite existing settings when overwrites is false", function ()
      set_mod_data({ ["my-lab"] = { animation = "proto-anim", scale = 5 } })
      local r = LabRegistry.new()
      r:register("my-lab", { animation = "runtime-anim", scale = 1 })
      r:load_prototype_settings(false)
      local settings = r:get_overlay_settings("my-lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("runtime-anim", settings.animation)
      assert.are.equal(1, settings.scale)
    end)

    it("loads unregistered labs even when overwrites is false", function ()
      set_mod_data({ ["new-lab"] = { animation = "proto-anim", scale = 2 } })
      local r = LabRegistry.new()
      r:load_prototype_settings(false)
      local settings = r:get_overlay_settings("new-lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("proto-anim", settings.animation)
      assert.are.equal(2, settings.scale)
    end)

    it("loads a copy of settings (not a reference to the prototype data)", function ()
      set_mod_data({ ["my-lab"] = { animation = "proto-anim", scale = 2 } })
      local r = LabRegistry.new()
      r:load_prototype_settings(true)
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
