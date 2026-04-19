local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

_G.mods["outer-rim"] = "1.0.0"
local Mod = require("scripts.prototype.mods.outer-rim")

describe("mods/outer-rim", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    _G.mods["outer-rim"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["outer-rim-thermodynamic-science-pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["outer-rim-cryochemical-science-pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["outer-rim-insulation-science-pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["outer-rim-spacecraft-science-pack"])
    end)
  end)
end)
