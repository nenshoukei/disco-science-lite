local assert = require("luassert")
local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["dea-dia-system"] = "1.0.0"
local Mod = require("scripts.prototype.mods.dea-dia-system")

describe("mods/dea-dia-system", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    _G.mods["dea-dia-system"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers thermodynamics-lab", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["thermodynamics-lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    --- @type data.Animation
    local on_animation

    before_each(function ()
      -- Source: https://github.com/Frontrider/dea-dia-system/blob/master/prototype/entity/thermodynamic-lab.lua#L59
      on_animation = {
        layers = {
          {
            filename = "__dea-dia-system__/graphics/entity/thermodynamics-laboratory/thermodynamics-laboratory.png",
            frame_count = 50,
            width = 2560 / 8,
            height = 2240 / 7,
          },
          {
            filename = "__dea-dia-system__/graphics/entity/thermodynamics-laboratory/thermodynamics-laboratory-emission.png",
            frame_count = 50,
            width = 2560 / 8,
            height = 2240 / 7,
          },
          {
            filename = "__dea-dia-system__/graphics/entity/thermodynamics-laboratory/thermodynamics-laboratory-shadow.png",
            frame_count = 50,
            width = 3200 / 8,
            height = 4800 / 7,
          },
        },
      }
      _G.data.raw.lab["thermodynamics-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes emission layer", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      Helper.assert_animation.has_layers({
        "__dea-dia-system__/graphics/entity/thermodynamics-laboratory/thermodynamics-laboratory.png",
        "__dea-dia-system__/graphics/entity/thermodynamics-laboratory/thermodynamics-laboratory-shadow.png",
      }, on_animation)
    end)

    it("defines overlay animation", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      local overlay = _G.data.raw["animation"]["mks-dsl-thermodynamics-lab-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay - nil
    end)
  end)
end)
