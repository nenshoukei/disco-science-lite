local Helper = require("spec.helper")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["BigLabFork"] = "1.0.0"
local Mod = require("scripts.prototype.mods.BigLabFork")

describe("mods/BigLabFork", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeLabRegistry.reset()
    _G.mods["BigLabFork"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers big-lab", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["big-lab"])
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
      _G.data.raw.lab["big-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("applies modifications to big-lab", function ()
      Mod.on_data_final_fixes()

      assert.are.equal(3, #on_animation.layers)
      assert.are.equal("__disco-science-lite__/graphics/factorio/lab-mask.png", on_animation.layers[1].filename)
      assert.are.equal("__base__/graphics/entity/lab/lab-integration.png", on_animation.layers[2].filename)
      assert.are.equal("__base__/graphics/entity/lab/lab-shadow.png", on_animation.layers[3].filename)
      Helper.assert_animation.frozen(1, on_animation)
    end)
  end)
end)
