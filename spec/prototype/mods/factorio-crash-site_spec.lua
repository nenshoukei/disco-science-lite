local assert = require("luassert")
local Helper = require("spec.helper")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["factorio-crash-site"] = "1.0.0"
_G.mods["atan-crash-site"] = "1.0.0"
_G.mods["kry-crash-site-settings"] = "1.0.0"
local Mod = require("scripts.prototype.mods.factorio-crash-site")

describe("mods/factorio-crash-site", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeLabRegistry.reset()
    _G.mods["factorio-crash-site"] = "1.0.0"
    _G.mods["atan-crash-site"] = "1.0.0"
    _G.mods["kry-crash-site-settings"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers crash-site-lab-repaired", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["crash-site-lab-repaired"])
    end)

    it("registers crash-site-lab", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["crash-site-lab"])
    end)

    it("registers crash-site-kry-lab", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["crash-site-kry-lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    --- @type data.Animation
    local on_animation_csl
    --- @type data.Animation
    local on_animation_cskl

    before_each(function ()
      -- No public code repository
      local on_animation = {
        layers = {
          { filename = "__factorio-crash-site__/graphics/entity/crash-site-lab/hr-crash-site-lab-repaired.png" },
          { filename = "__factorio-crash-site__/graphics/entity/crash-site-lab/hr-crash-site-lab-repaired-beams.png" },
          { filename = "__factorio-crash-site__/graphics/entity/crash-site-lab/hr-crash-site-lab-repaired-shadow.png" },
        },
      }

      on_animation_csl = Helper.table_deep_copy(on_animation)
      on_animation_cskl = Helper.table_deep_copy(on_animation)
      _G.data.raw.lab["crash-site-lab"] = ({ on_animation = on_animation_csl }) --[[@as data.LabPrototype]]
      _G.data.raw.lab["crash-site-kry-lab"] = ({ on_animation = on_animation_cskl }) --[[@as data.LabPrototype]]
    end)

    it("applies modifications to crash-site-lab", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      Helper.assert_animation.has_layers({
        "__factorio-crash-site__/graphics/entity/crash-site-lab/hr-crash-site-lab-repaired.png",
        "__factorio-crash-site__/graphics/entity/crash-site-lab/hr-crash-site-lab-repaired-shadow.png",
      }, on_animation_csl)
    end)

    it("applies modifications to crash-site-kry-lab", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      Helper.assert_animation.has_layers({
        "__factorio-crash-site__/graphics/entity/crash-site-lab/hr-crash-site-lab-repaired.png",
        "__factorio-crash-site__/graphics/entity/crash-site-lab/hr-crash-site-lab-repaired-shadow.png",
      }, on_animation_cskl)
    end)
  end)
end)
