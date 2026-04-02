local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["linox"] = "1.0.0"
local Mod = require("scripts.prototype.mods.linox")

describe("mods/linox", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    _G.mods["linox"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["linox-item_dysprosium-data-card"])
    end)

    it("excludes linox-building_linox-supercomputer", function ()
      Mod.on_data()
      assert.is_true(PrototypeLabRegistry.excluded_labs["linox-building_linox-supercomputer"])
    end)
  end)
end)
