local Helper = require("spec.helper")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["5dim_automation"] = "1.0.0"
local Mod = require("scripts.prototype.mods.5dim")

describe("mods/5dim", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeLabRegistry.reset()
    _G.mods["5dim_automation"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers all 9 labs", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["5d-lab-02"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["5d-lab-03"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["5d-lab-04"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["5d-lab-05"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["5d-lab-06"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["5d-lab-07"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["5d-lab-08"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["5d-lab-09"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["5d-lab-10"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- Source: https://github.com/McGuten/Factorio5DimMods/blob/master/5dim_core/lib/automation/generation-lab.lua
      -- on_animation is copied from vanilla lab, and layers[1].filename is set to `lab-{number}.png`
      on_animation = {
        layers = {
          { filename = "__5dim_automation__/graphics/entities/lab/lab-02.png", frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-integration.png",     frame_count = 1, repeat_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-light.png",           frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-shadow.png",          frame_count = 1, repeat_count = 33 },
        },
      }
      _G.data.raw.lab["5d-lab-02"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("applies vanilla lab modifications to 5d-lab", function ()
      Mod.on_data_final_fixes()

      Helper.assert_animation.is_vanilla_lab_modifications_applied(on_animation)
    end)
  end)
end)
