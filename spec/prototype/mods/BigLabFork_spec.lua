local assert = require("luassert")
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
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["big-lab"])
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
      _G.data.raw.lab["big-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("applies modifications to big-lab", function ()
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
