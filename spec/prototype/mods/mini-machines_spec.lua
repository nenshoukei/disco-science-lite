local Helper = require("spec.helper")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["mini-machines"] = "1.0.0"
local Mod = require("scripts.prototype.mods.mini-machines")

describe("mods/mini-machines", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeLabRegistry.reset()
    _G.mods["mini-machines"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers labs", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["mini-lab-1"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["mini-biolab-1"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["mini-alien-lab-1"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation_lab    --- @type data.Animation
    local on_animation_biolab --- @type data.Animation
    local on_animation_alien  --- @type data.Animation

    before_each(function ()
      -- Source: https://github.com/wube/factorio-data/blob/master/base/prototypes/entity/entities.lua#L3830
      on_animation_lab = {
        layers = {
          { filename = "__base__/graphics/entity/lab/lab.png",             frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-integration.png", frame_count = 1, repeat_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-light.png",       frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-shadow.png",      frame_count = 1, repeat_count = 33 },
        },
      }
      _G.data.raw.lab["mini-lab-1"] = ({ on_animation = on_animation_lab }) --[[@as data.LabPrototype]]

      -- Source: https://github.com/wube/factorio-data/blob/master/space-age/prototypes/entity/entities.lua#L1607
      on_animation_biolab = {
        layers = {
          { filename = "__space-age__/graphics/entity/biolab/biolab-anim.png",   frame_count = 32 },
          { filename = "__space-age__/graphics/entity/biolab/biolab-lights.png", frame_count = 32 },
          { filename = "__space-age__/graphics/entity/biolab/biolab-shadow.png", frame_count = 32 },
        },
      }
      _G.data.raw.lab["mini-biolab-1"] = ({ on_animation = on_animation_biolab }) --[[@as data.LabPrototype]]

      -- Source: https://github.com/modded-factorio/bobsmods/blob/main/bobtech/prototypes/entity/entity-alien.lua#L22
      on_animation_alien = {
        layers = {
          { filename = "__bobtech__/graphics/entity/lab/lab-alien.png",       frame_count = 33 },
          { filename = "__bobtech__/graphics/entity/lab/lab-integration.png", frame_count = 1, repeat_count = 33 },
          { filename = "__bobtech__/graphics/entity/lab/lab-alien-light.png", frame_count = 33 },
          { filename = "__bobtech__/graphics/entity/lab/lab-shadow.png",      frame_count = 1, repeat_count = 33 },
        },
      }
      _G.data.raw.lab["mini-alien-lab-1"] = ({ on_animation = on_animation_alien }) --[[@as data.LabPrototype]]
    end)

    it("applies modifications to mini-lab-1", function ()
      Mod.on_data_final_fixes()

      assert.are.equal(3, #on_animation_lab.layers)
      assert.are.equal("__disco-science-lite__/graphics/factorio/lab-mask.png", on_animation_lab.layers[1].filename)
      assert.are.equal("__base__/graphics/entity/lab/lab-integration.png", on_animation_lab.layers[2].filename)
      assert.are.equal("__base__/graphics/entity/lab/lab-shadow.png", on_animation_lab.layers[3].filename)
      Helper.assert_animation.frozen(1, on_animation_lab)
    end)

    it("applies modifications to mini-biolab-1", function ()
      Mod.on_data_final_fixes()

      assert.are.equal(2, #on_animation_biolab.layers)
      assert.are.equal("__space-age__/graphics/entity/biolab/biolab-anim.png", on_animation_biolab.layers[1].filename)
      assert.are.equal("__space-age__/graphics/entity/biolab/biolab-shadow.png", on_animation_biolab.layers[2].filename)
    end)
    it("applies modifications to mini-alien-lab-1", function ()
      Mod.on_data_final_fixes()

      assert.are.equal(3, #on_animation_alien.layers)
      assert.are.equal("__disco-science-lite__/graphics/factorio/lab-mask.png", on_animation_alien.layers[1].filename)
      assert.are.equal("__bobtech__/graphics/entity/lab/lab-integration.png", on_animation_alien.layers[2].filename)
      assert.are.equal("__bobtech__/graphics/entity/lab/lab-shadow.png", on_animation_alien.layers[3].filename)
      Helper.assert_animation.frozen(1, on_animation_alien)
    end)
  end)
end)
