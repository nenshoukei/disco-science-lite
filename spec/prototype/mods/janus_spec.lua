local assert = require("luassert")
local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

_G.mods["janus"] = "1.0.0"
local Mod = require("scripts.prototype.mods.janus")

describe("mods/janus", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    _G.mods["janus"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["janus-time-science-pack"])
    end)
  end)
end)
