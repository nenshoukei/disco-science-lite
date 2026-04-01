local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

_G.mods["omnia"] = "1.0.0"
local Mod = require("scripts.prototype.mods.omnia")

describe("mods/omnia", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    _G.mods["omnia"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["omnia-basic-science-pack"])
    end)
  end)
end)
