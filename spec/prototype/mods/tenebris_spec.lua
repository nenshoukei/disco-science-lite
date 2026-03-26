local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

_G.mods["tenebris"] = "1.0.0"
local Mod = require("scripts.prototype.mods.tenebris")

describe("mods/tenebris", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    _G.mods["tenebris"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors for bioluminescent-science-pack", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["bioluminescent-science-pack"])
    end)
  end)
end)
