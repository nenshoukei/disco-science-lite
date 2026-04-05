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
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["alien-science-pack"])
    end)

    it("registers scaled labs", function ()
      Mod.on_data()
      for i = 1, 6 do
        assert.is_not_nil(PrototypeLabRegistry.registered_labs["lab-MS-" .. i])
      end
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- Source: https://github.com/wube/factorio-data/blob/master/base/prototypes/entity/entities.lua#L3830
      on_animation = {
        layers = {
          { filename = "__base__/graphics/entity/lab/lab.png",             frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-integration.png", frame_count = 1, repeat_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-light.png",       frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-shadow.png",      frame_count = 1, repeat_count = 33 },
        },
      }
      _G.data.raw.lab["lab-MS-1"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("applies modifications to lab-MS-1", function ()
      Mod.on_data_final_fixes()

      assert.are.equal(3, #on_animation.layers)
      assert.are.equal("__disco-science-lite__/graphics/factorio/lab-mask.png", on_animation.layers[1].filename)
      assert.are.equal("__base__/graphics/entity/lab/lab-integration.png", on_animation.layers[2].filename)
      assert.are.equal("__base__/graphics/entity/lab/lab-shadow.png", on_animation.layers[3].filename)
      Helper.assert_animation.frozen(1, on_animation)
    end)
  end)
end)
