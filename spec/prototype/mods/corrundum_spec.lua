local assert = require("luassert")
local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["corrundum"] = "1.0.0"
local Mod = require("scripts.prototype.mods.corrundum")

describe("mods/corrundum", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    _G.mods["corrundum"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers color for electrochemical-science-pack", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["electrochemical-science-pack"])
    end)

    it("registers pressure-lab", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["pressure-lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    --- @type data.Animation
    local on_animation

    before_each(function ()
      Helper.load_animation_definitions()

      -- Source: https://github.com/ZacharyDK/Corrundum/blob/main/corrundum/prototypes/entities.lua#L462
      on_animation = {
        layers = {
          { filename = "__corrundum__/graphics/entity/lab-3-x-frame.png", frame_count = 47 },
          { filename = "__corrundum__/graphics/entity/chem-lab-on-mask.png", frame_count = 1, repeat_count = 47 },
          { filename = "__corrundum__/graphics/entity/chemical-plant-smoke-outer-blue.png", frame_count = 47 },
          { filename = "__corrundum__/graphics/entity/chemical-plant-smoke-inner-blue.png", frame_count = 47 },
          { filename = "__base__/graphics/entity/lab/lab-integration.png", frame_count = 1, repeat_count = 47 },
          { filename = "__corrundum__/graphics/entity/lab-light-three-times-frames-no-change.png", frame_count = 47 },
          { filename = "__base__/graphics/entity/lab/lab-shadow.png", frame_count = 1, repeat_count = 47 },
        },
      }
      _G.data.raw.lab["pressure-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes smoke and light layers, creates overlay with 3 layers and a companion", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      Helper.assert_animation.has_layers({
        "__corrundum__/graphics/entity/lab-3-x-frame.png",
        "__corrundum__/graphics/entity/chem-lab-on-mask.png",
        "__base__/graphics/entity/lab/lab-integration.png",
        "__base__/graphics/entity/lab/lab-shadow.png",
      }, on_animation)

      Helper.assert_animation.frozen(1, on_animation)

      local overlay = _G.data.raw["animation"]["mks-dsl-pressure-lab-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay - nil
      assert.is_not_nil(overlay.layers)
      assert.are.equal(3, #overlay.layers)

      local companion = _G.data.raw["animation"]["mks-dsl-pressure-lab-companion"]
      assert.is_not_nil(companion)
    end)
  end)
end)
