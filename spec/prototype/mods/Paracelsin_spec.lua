local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

_G.mods["Paracelsin"] = "1.0.0"
local Mod = require("scripts.prototype.mods.Paracelsin")

describe("mods/Paracelsin", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    _G.mods["Paracelsin"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors for science packs", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["galvanization-science-pack"])
    end)
  end)
end)
