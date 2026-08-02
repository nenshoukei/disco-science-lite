local assert = require("luassert")
local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["pycoalprocessing"] = "1.0.0"
local Mod = require("scripts.prototype.mods.pyanodon")

describe("mods/pyanodon", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    -- Each test sets its own mods; start with none active.
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers py-science-pack colors when only pyalienlife is active", function ()
      _G.mods["pyalienlife"] = "1.0.0"

      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()

      assert.is_not_nil(PrototypeColorRegistry.registered_colors["py-science-pack-1"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["py-science-pack-2"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["py-science-pack-3"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["py-science-pack-4"])
      -- Only pycoalprocessing registers a lab.
      assert.is_nil(PrototypeLabRegistry.registered_labs["lab"])
    end)

    it("registers production-science-pack color when only pyfusionenergy is active", function ()
      _G.mods["pyfusionenergy"] = "1.0.0"

      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()

      assert.is_not_nil(PrototypeColorRegistry.registered_colors["production-science-pack"])
    end)

    it("registers lab override when only pycoalprocessing is active", function ()
      _G.mods["pycoalprocessing"] = "1.0.0"

      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()

      assert.is_not_nil(PrototypeLabRegistry.registered_labs["lab"])
      -- py-science-pack colors are not registered without pyalienlife.
      assert.is_nil(PrototypeColorRegistry.registered_colors["py-science-pack-1"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    --- @type data.Animation
    local on_animation

    before_each(function ()
      -- Source: https://github.com/pyanodon/pycoalprocessing/blob/master/prototypes/buildings/lab.lua#L15
      on_animation = {
        layers = {
          { filename = "__pycoalprocessinggraphics__/graphics/entity/lab-mk01/raw.png", frame_count = 30 },
          { filename = "__pycoalprocessinggraphics__/graphics/entity/lab-mk01/l.png", frame_count = 1, repeat_count = 60 },
          { filename = "__pycoalprocessinggraphics__/graphics/entity/lab-mk01/beam.png", frame_count = 60 },
          { filename = "__pycoalprocessinggraphics__/graphics/entity/lab-mk01/beam.png", frame_count = 60 },
          { filename = "__pycoalprocessinggraphics__/graphics/entity/lab-mk01/sh.png", frame_count = 1, repeat_count = 60 },
        },
      }
      _G.data.raw.lab["lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("does nothing when pycoalprocessing is not active", function ()
      _G.mods["pyalienlife"] = "1.0.0"

      assert.no_error(function ()
        assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
        Mod.on_data_final_fixes()
      end)

      -- on_animation must be untouched.
      assert.are.equal(5, #on_animation.layers)
      assert.is_nil(_G.data.raw["animation"]["mks-dsl-pyanodon-lab-overlay"])
    end)

    it("removes l and both beam layers, replaces raw filename, and creates overlay with 2 layers", function ()
      _G.mods["pycoalprocessing"] = "1.0.0"

      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      Helper.assert_animation.has_layers({
        "__pycoalprocessinggraphics__/graphics/entity/lab-mk01/raw-bw.png",
        "__pycoalprocessinggraphics__/graphics/entity/lab-mk01/sh.png",
      }, on_animation)

      local overlay = _G.data.raw["animation"]["mks-dsl-pyanodon-lab-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay - nil
      assert.are.equal(2, #overlay.layers)
    end)
  end)
end)
