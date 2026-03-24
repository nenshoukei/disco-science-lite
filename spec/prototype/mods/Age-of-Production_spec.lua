local Helper = require("spec.helper")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["Age-of-Production"] = "1.0.0"
local Mod = require("scripts.prototype.mods.Age-of-Production")

describe("mods/Age-of-Production", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeLabRegistry.reset()
    _G.mods["Age-of-Production"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers aop-quantum-computer", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["aop-quantum-computer"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- Source: https://github.com/AndreusAxolotl/Age-of-Production/blob/main/prototypes/entities.lua#L4012
      on_animation = {
        layers = {
          { filename = "__Age-of-Production-Graphics__/graphics/entity/quantum-computer/quantum-computer-hr-animation-1.png" },
          { filename = "__Age-of-Production-Graphics__/graphics/entity/quantum-computer/quantum-computer-hr-emission-1.png" },
          { filename = "__Age-of-Production-Graphics__/graphics/entity/quantum-computer/quantum-computer-hr-shadow.png" },
        },
      }
      _G.data.raw.lab["aop-quantum-computer"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes the emission layer and creates overlay", function ()
      Mod.on_data_final_fixes()

      assert.are.equal(2, #on_animation.layers)
      assert.are.equal(
        "__Age-of-Production-Graphics__/graphics/entity/quantum-computer/quantum-computer-hr-animation-1.png",
        on_animation.layers[1].filename
      )
      assert.are.equal(
        "__Age-of-Production-Graphics__/graphics/entity/quantum-computer/quantum-computer-hr-shadow.png",
        on_animation.layers[2].filename
      )

      local overlay = _G.data.raw["animation"]["mks-dsl-aop-quantum-computer-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay -nil
      assert.are.equal("__disco-science-lite__/graphics/hurricane/fusion-reactor-hr-overlay.png", overlay.filename)
    end)

    it("does not extend when emission layer is missing", function ()
      _G.data.raw.lab["aop-quantum-computer"].on_animation = {
        layers = {
          { filename = "__Age-of-Production-Graphics__/graphics/entity/quantum-computer/quantum-computer-hr-animation-1.png" },
        },
      }

      Mod.on_data_final_fixes()

      assert.is_nil(_G.data.raw["animation"]["mks-dsl-aop-quantum-computer-overlay"])
    end)
  end)
end)
