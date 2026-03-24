local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["Moshine"] = "1.0.0"
local Mod = require("scripts.prototype.mods.Moshine")

describe("mods/Moshine", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    _G.mods["Moshine"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors for datacells", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["datacell-empty"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["datacell-solved-equation"])
    end)

    it("registers neural_computer lab", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["neural_computer"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- Source: https://github.com/snouz/Moshine/blob/main/prototypes/entity/supercomputer.lua#L9
      on_animation = {
        layers = {
          { filename = "__Moshine__/graphics/entity/supercomputer/teleporter-shadow.png",   frame_count = 1,  repeat_count = 45 },
          { filename = "__Moshine__/graphics/entity/supercomputer/teleporter-base.png",     repeat_count = 45 },
          { filename = "__Moshine__/graphics/entity/supercomputer/supercomputer_glow.png",  repeat_count = 45 },
          { filename = "__Moshine__/graphics/entity/supercomputer/supercomputer_light.png", repeat_count = 45 },
          { filename = "__Moshine__/graphics/entity/supercomputer/supercomputer_anim.png",  frame_count = 45 },
        },
      }
      _G.data.raw.lab["neural_computer"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes glow/light/anim layers and creates overlay with 3 layers", function ()
      Mod.on_data_final_fixes()

      -- 5 original - 3 removed (glow, light, anim) = 2
      assert.are.equal(2, #on_animation.layers)
      assert.are.equal("__Moshine__/graphics/entity/supercomputer/teleporter-shadow.png", on_animation.layers[1].filename)
      assert.are.equal("__Moshine__/graphics/entity/supercomputer/teleporter-base.png", on_animation.layers[2].filename)

      local overlay = _G.data.raw["animation"]["mks-dsl-neural_computer-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay -nil
      assert.are.equal(3, #overlay.layers)
    end)

    it("does not extend when any layer is missing", function ()
      _G.data.raw.lab["neural_computer"].on_animation = {
        layers = {
          { filename = "__Moshine__/graphics/entity/supercomputer/teleporter-base.png", repeat_count = 45 },
        },
      }

      Mod.on_data_final_fixes()

      assert.is_nil(_G.data.raw["animation"]["mks-dsl-neural_computer-overlay"])
    end)
  end)
end)
