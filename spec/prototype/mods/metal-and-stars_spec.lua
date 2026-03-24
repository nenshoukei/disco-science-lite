local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["metal-and-stars"] = "1.0.0"
local Mod = require("scripts.prototype.mods.metal-and-stars")

describe("mods/metal-and-stars", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    _G.mods["metal-and-stars"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors for metal-and-stars science packs", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["quantum-science-pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["ring-science-pack"])
    end)

    it("registers microgravity-lab", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["microgravity-lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- Source: https://github.com/aboucher51/metal-and-stars/blob/main/prototypes/entity/particle-accelerator.lua#L60
      on_animation = {
        layers = {
          { filename = "__metal-and-stars-graphics__/graphics/entity/particle-accelerator/particle-accelerator-hr-shadow.png",             frame_count = 1, repeat_count = 60 },
          { filename = "__metal-and-stars-graphics__/graphics/entity/particle-accelerator/particle-accelerator-hr-animation.png",          frame_count = 60 },
          { filename = "__metal-and-stars-graphics__/graphics/entity/particle-accelerator/particle-accelerator-hr-animation-emission.png", frame_count = 60 },
        },
      }
      _G.data.raw.lab["microgravity-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes the emission layer and creates overlay with stripes", function ()
      Mod.on_data_final_fixes()

      -- 3 original - 1 emission removed = 2
      assert.are.equal(2, #on_animation.layers)
      assert.are.equal("__metal-and-stars-graphics__/graphics/entity/particle-accelerator/particle-accelerator-hr-shadow.png", on_animation.layers[1].filename)
      assert.are.equal("__metal-and-stars-graphics__/graphics/entity/particle-accelerator/particle-accelerator-hr-animation.png", on_animation.layers[2]
        .filename)

      local overlay = _G.data.raw["animation"]["mks-dsl-microgravity-lab-overlay"]
      assert.is_not_nil(overlay)
      --- @cast overlay -nil
      assert.is_not_nil(overlay.stripes)
      assert.are.equal(
        "__disco-science-lite__/graphics/hurricane/fusion-reactor-hr-overlay.png",
        overlay.stripes[1].filename
      )
    end)

    it("does not extend when emission layer is missing", function ()
      _G.data.raw.lab["microgravity-lab"].on_animation = {
        layers = {
          { filename = "__metal-and-stars-graphics__/graphics/entity/particle-accelerator/particle-accelerator-hr-animation.png", frame_count = 60 },
        },
      }

      Mod.on_data_final_fixes()

      assert.is_nil(_G.data.raw["animation"]["mks-dsl-microgravity-lab-overlay"])
    end)
  end)
end)
