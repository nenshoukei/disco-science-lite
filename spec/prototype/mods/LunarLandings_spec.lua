local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

_G.mods["LunarLandings"] = "1.0.0"
local Mod = require("scripts.prototype.mods.LunarLandings")

describe("mods/LunarLandings", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    _G.mods["LunarLandings"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["ll-quantum-science-pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["ll-space-science-pack"])
    end)
  end)
end)
