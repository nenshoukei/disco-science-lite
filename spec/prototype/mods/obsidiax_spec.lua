local assert = require("luassert")
local Helper = require("spec.helper")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["obsidiax"] = "1.0.0"
local Mod = require("scripts.prototype.mods.obsidiax")

describe("mods/obsidiax", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeLabRegistry.reset()
    _G.mods["obsidiax"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("excludes obsidiax-lab", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_true(PrototypeLabRegistry.excluded_labs["obsidiax-lab"])
    end)
  end)
end)
