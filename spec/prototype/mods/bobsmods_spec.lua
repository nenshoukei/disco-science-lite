local Helper = require("spec.helper")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["bobtech"] = "1.0.0"
local Mod = require("scripts.prototype.mods.bobsmods")

describe("mods/bobsmods", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeLabRegistry.reset()
    _G.mods["bobtech"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers all 3 bob labs", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["bob-lab-2"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["bob-burner-lab"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["bob-lab-alien"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation_vanilla_lab --- @type data.Animation
    local on_animation_lab2        --- @type data.Animation
    local on_animation_burner      --- @type data.Animation
    local on_animation_alien       --- @type data.Animation

    before_each(function ()
      --- Dummy on_animation for vanilla lab
      on_animation_vanilla_lab = {
        layers = {
          { filename = "dummy.png" },
        },
      }
      _G.data.raw.lab["lab"] = ({ on_animation = on_animation_vanilla_lab }) --[[@as data.LabPrototype]]

      -- Source: https://github.com/modded-factorio/bobsmods/blob/main/bobtech/prototypes/entity/entity.lua#L15
      on_animation_lab2 = {
        layers = {
          { filename = "__bobtech__/graphics/entity/lab/lab2.png",            frame_count = 33 },
          { filename = "__bobtech__/graphics/entity/lab/lab-integration.png", frame_count = 1, repeat_count = 33 },
          { filename = "__bobtech__/graphics/entity/lab/lab2-light.png",      frame_count = 33 },
          { filename = "__bobtech__/graphics/entity/lab/lab-shadow.png",      frame_count = 1, repeat_count = 33 },
        },
      }
      _G.data.raw.lab["bob-lab-2"] = ({ on_animation = on_animation_lab2 }) --[[@as data.LabPrototype]]

      -- Source: https://github.com/modded-factorio/bobsmods/blob/main/bobtech/prototypes/entity/entity.lua#L180
      on_animation_burner = {
        layers = {
          { filename = "__bobtech__/graphics/entity/lab/burner-lab.png",      frame_count = 33 },
          { filename = "__bobtech__/graphics/entity/lab/lab-integration.png", frame_count = 1, repeat_count = 33 },
          { filename = "__bobtech__/graphics/entity/lab/lab-shadow.png",      frame_count = 1, repeat_count = 33 },
        },
      }
      _G.data.raw.lab["bob-burner-lab"] = ({ on_animation = on_animation_burner }) --[[@as data.LabPrototype]]

      -- Source: https://github.com/modded-factorio/bobsmods/blob/main/bobtech/prototypes/entity/entity-alien.lua#L22
      on_animation_alien = {
        layers = {
          { filename = "__bobtech__/graphics/entity/lab/lab-alien.png",       frame_count = 33 },
          { filename = "__bobtech__/graphics/entity/lab/lab-integration.png", frame_count = 1, repeat_count = 33 },
          { filename = "__bobtech__/graphics/entity/lab/lab-alien-light.png", frame_count = 33 },
          { filename = "__bobtech__/graphics/entity/lab/lab-shadow.png",      frame_count = 1, repeat_count = 33 },
        },
      }
      _G.data.raw.lab["bob-lab-alien"] = ({ on_animation = on_animation_alien }) --[[@as data.LabPrototype]]
    end)

    it("copies on_animation layers from vanilla lab to bob-lab-2", function ()
      Mod.on_data_final_fixes()

      assert.are.equal(on_animation_vanilla_lab.layers, on_animation_lab2.layers)
    end)

    it("freezes bob-burner-lab without removing any layer", function ()
      Mod.on_data_final_fixes()

      assert.are.equal(3, #on_animation_burner.layers)
      Helper.assert_animation.frozen(1, on_animation_burner)
    end)

    it("copies on_animation layers from vanilla lab to to bob-lab-alien", function ()
      Mod.on_data_final_fixes()

      assert.are.equal(on_animation_vanilla_lab.layers, on_animation_alien.layers)
    end)
  end)
end)
