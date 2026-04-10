local Helper = require("spec.helper")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["atan-crash-site"] = "1.0.0"
local Mod = require("scripts.prototype.mods.atan-crash-site")

describe("mods/atan-crash-site", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeLabRegistry.reset()
    _G.mods["atan-crash-site"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("excludes the crash site lab", function ()
      Mod.on_data()
      assert.is_true(PrototypeLabRegistry.excluded_labs["crash-site-lab"])
    end)
  end)
end)
