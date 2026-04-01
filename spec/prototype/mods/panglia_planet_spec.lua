local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

_G.mods["panglia_planet"] = "1.0.0"
local Mod = require("scripts.prototype.mods.panglia_planet")

describe("mods/panglia_planet", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    _G.mods["panglia_planet"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["datacell-dna-raw"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["datacell-dna-sequenced"])
    end)
  end)
end)
