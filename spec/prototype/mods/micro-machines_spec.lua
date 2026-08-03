local assert = require("luassert")
local Helper = require("spec.helper")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["micro-machines"] = "1.0.0"
local Mod = require("scripts.prototype.mods.micro-machines")

describe("mods/micro-machines", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeLabRegistry.reset()
    _G.mods["micro-machines"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers labs", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["micro-lab-1"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["micro-biolab-1"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["micro-alien-lab-1"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    --- @type data.Animation
    local on_animation_lab
    --- @type data.Animation
    local on_animation_biolab
    --- @type data.Animation
    local on_animation_alien

    before_each(function ()
      -- Source: https://github.com/wube/factorio-data/blob/master/base/prototypes/entity/entities.lua#L3830
      on_animation_lab = {
        layers = {
          { filename = "__base__/graphics/entity/lab/lab.png", frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-integration.png", frame_count = 1, repeat_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-light.png", frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-shadow.png", frame_count = 1, repeat_count = 33 },
        },
      }
      _G.data.raw.lab["micro-lab-1"] = ({ on_animation = on_animation_lab }) --[[@as data.LabPrototype]]

      -- Source: https://github.com/wube/factorio-data/blob/master/space-age/prototypes/entity/entities.lua#L1607
      on_animation_biolab = {
        layers = {
          { filename = "__space-age__/graphics/entity/biolab/biolab-anim.png", frame_count = 32 },
          { filename = "__space-age__/graphics/entity/biolab/biolab-lights.png", frame_count = 32 },
          { filename = "__space-age__/graphics/entity/biolab/biolab-shadow.png", frame_count = 32 },
        },
      }
      _G.data.raw.lab["micro-biolab-1"] = ({ on_animation = on_animation_biolab }) --[[@as data.LabPrototype]]

      -- Source: https://github.com/modded-factorio/bobsmods/blob/main/bobtech/prototypes/entity/entity-alien.lua#L22
      on_animation_alien = {
        layers = {
          { filename = "__bobtech__/graphics/entity/lab/lab-alien.png", frame_count = 33 },
          { filename = "__bobtech__/graphics/entity/lab/lab-integration.png", frame_count = 1, repeat_count = 33 },
          { filename = "__bobtech__/graphics/entity/lab/lab-alien-light.png", frame_count = 33 },
          { filename = "__bobtech__/graphics/entity/lab/lab-shadow.png", frame_count = 1, repeat_count = 33 },
        },
      }
      _G.data.raw.lab["micro-alien-lab-1"] = ({ on_animation = on_animation_alien }) --[[@as data.LabPrototype]]
    end)

    it("applies modifications to micro-lab-1", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      Helper.assert_animation.has_layers({
        "__disco-science-lite__/graphics/factorio/lab-darkened.png",
        "__base__/graphics/entity/lab/lab-integration.png",
        "__base__/graphics/entity/lab/lab-shadow.png",
      }, on_animation_lab)

      Helper.assert_animation.frozen(1, on_animation_lab)
    end)

    it("applies modifications to micro-biolab-1", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      Helper.assert_animation.has_layers({
        "__space-age__/graphics/entity/biolab/biolab-anim.png",
        "__space-age__/graphics/entity/biolab/biolab-shadow.png",
      }, on_animation_biolab)
    end)

    it("applies modifications to micro-alien-lab-1", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      Helper.assert_animation.has_layers({
        "__disco-science-lite__/graphics/factorio/lab-darkened.png",
        "__bobtech__/graphics/entity/lab/lab-integration.png",
        "__bobtech__/graphics/entity/lab/lab-shadow.png",
      }, on_animation_alien)

      Helper.assert_animation.frozen(1, on_animation_alien)
    end)
  end)
end)
