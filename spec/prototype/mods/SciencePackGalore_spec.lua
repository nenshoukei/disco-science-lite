local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

_G.mods["SciencePackGaloreForked"] = "1.0.0"
local Mod = require("scripts.prototype.mods.SciencePackGalore")

describe("mods/SciencePackGaloreForked", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    _G.mods["SciencePackGaloreForked"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors", function ()
      Mod.on_data()
      for i = 1, 36 do
        assert.is_not_nil(PrototypeColorRegistry.registered_colors["sem-spg_science-pack-" .. i])
      end
    end)
  end)
end)
