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
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["thermodynamics-lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- Source: https://github.com/Frontrider/dea-dia-system/blob/master/prototype/entity/thermodynamic-lab.lua#L59
      on_animation = {
        layers = {
          { filename = "__dea-dia-system__/graphics/entity/thermodynamics-laboratory/thermodynamics-laboratory.png",          frame_count = 50, width = 2560 / 8, height = 2240 / 7 },
          { filename = "__dea-dia-system__/graphics/entity/thermodynamics-laboratory/thermodynamics-laboratory-emission.png", frame_count = 50, width = 2560 / 8, height = 2240 / 7 },
          { filename = "__dea-dia-system__/graphics/entity/thermodynamics-laboratory/thermodynamics-laboratory-shadow.png",   frame_count = 50, width = 3200 / 8, height = 4800 / 7 },
        },
      }
      _G.data.raw.lab["thermodynamics-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes emission layer", function ()
      Mod.on_data_final_fixes()

      -- 3 original - 1 emission removed = 2
      assert.are.equal(2, #on_animation.layers)
      assert.are.equal("__dea-dia-system__/graphics/entity/thermodynamics-laboratory/thermodynamics-laboratory.png", on_animation.layers[1].filename)
      assert.are.equal("__dea-dia-system__/graphics/entity/thermodynamics-laboratory/thermodynamics-laboratory-shadow.png", on_animation.layers[2].filename)
    end)

    it("defines overlay animation", function ()
      Mod.on_data_final_fixes()

      local overlay = _G.data.raw["animation"]["mks-dsl-thermodynamics-lab-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay -nil
    end)
  end)
end)
