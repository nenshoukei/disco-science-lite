local Helper = require("spec.helper")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["CircularColliderLab"] = "1.0.0"
local Mod = require("scripts.prototype.mods.CircularColliderLab")

describe("mods/CircularColliderLab", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeLabRegistry.reset()
    _G.mods["CircularColliderLab"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers circular-collider-lab", function ()
      Mod.on_data()
      local registration = PrototypeLabRegistry.registered_labs["circular-collider-lab"]
      assert.is_not_nil(registration)
      assert.are.equal("mks-dsl-circular-collider-lab-overlay", registration.animation)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- No public code repository
      on_animation = {
        layers = {
          { filename = "__CircularColliderLab__/graphics/circular-collider-lab-animation.png" },
          { filename = "__CircularColliderLab__/graphics/circular-collider-lab-emission.png" },
          { filename = "__CircularColliderLab__/graphics/circular-collider-lab-shadow.png" },
        },
      }
      _G.data.raw.lab["circular-collider-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("modifies circular-collider-lab on_animation", function ()
      Mod.on_data_final_fixes()

      -- original 3 - emission 1 = 2
      assert.are.equal(2, #on_animation.layers)
      assert.are.equal("__CircularColliderLab__/graphics/circular-collider-lab-animation.png", on_animation.layers[1].filename)
      assert.are.equal("__CircularColliderLab__/graphics/circular-collider-lab-shadow.png", on_animation.layers[2].filename)
    end)

    it("defines overlay animation", function ()
      Mod.on_data_final_fixes()

      assert.is_not_nil(data.raw["animation"]["mks-dsl-circular-collider-lab-overlay"])
    end)
  end)
end)
