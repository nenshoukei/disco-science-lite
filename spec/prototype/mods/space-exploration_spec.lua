local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["space-exploration"] = "1.0.0"
local Mod = require("scripts.prototype.mods.space-exploration")

describe("mods/space-exploration", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    _G.mods["space-exploration"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors for science packs", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["se-rocket-science-pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["se-astronomic-science-pack-1"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["se-biological-science-pack-1"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["se-energy-science-pack-1"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["se-material-science-pack-1"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["se-deep-space-science-pack-1"])
    end)

    it("registers color overrides for vanilla science packs", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["production-science-pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["utility-science-pack"])
    end)

    it("excludes the space science lab", function ()
      Mod.on_data()
      assert.is_true(PrototypeLabRegistry.excluded_labs["se-space-science-lab"])
    end)
  end)
end)
