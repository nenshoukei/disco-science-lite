local assert = require("luassert")
local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["SchallAlienLoot"] = "1.0.0"
_G.mods["SchallMachineScaling"] = "1.0.0"
local Mod = require("scripts.prototype.mods.schallmods")

describe("mods/schallmods", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    _G.mods["SchallAlienLoot"] = "1.0.0"
    _G.mods["SchallMachineScaling"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers alien science pack color", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["alien-science-pack"])
    end)

    it("registers scaled labs", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      for i = 1, 6 do
        assert.is_not_nil(PrototypeLabRegistry.registered_labs["lab-MS-" .. i])
      end
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    --- @type data.Animation
    local on_animation

    before_each(function ()
      -- Source: https://github.com/wube/factorio-data/blob/master/base/prototypes/entity/entities.lua#L3830
      on_animation = {
        layers = {
          { filename = "__base__/graphics/entity/lab/lab.png", frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-integration.png", frame_count = 1, repeat_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-light.png", frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-shadow.png", frame_count = 1, repeat_count = 33 },
        },
      }
      _G.data.raw.lab["lab-MS-1"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("applies modifications to lab-MS-1", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      Helper.assert_animation.has_layers({
        "__disco-science-lite__/graphics/factorio/lab-darkened.png",
        "__base__/graphics/entity/lab/lab-integration.png",
        "__base__/graphics/entity/lab/lab-shadow.png",
      }, on_animation)

      Helper.assert_animation.frozen(1, on_animation)
    end)
  end)
end)
