local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["planet-muluna"] = "1.0.0"
local Mod = require("scripts.prototype.mods.planet-muluna")

describe("mods/planet-muluna", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    _G.mods["planet-muluna"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers color for interstellar-science-pack", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["interstellar-science-pack"])
    end)

    it("registers cryolab lab", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["cryolab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- Source: https://github.com/nicholasgower/planet-muluna/blob/main/prototypes/entity/cryolab.lua#L73
      on_animation = {
        layers = {
          { filename = "__muluna-graphics__/graphics/photometric-lab/photometric-lab-hr-shadow.png",      frame_count = 1,  repeat_count = 126 },
          { filename = "__muluna-graphics__/graphics/photometric-lab/photometric-lab-hr-animation-1.png", frame_count = 126 },
          { filename = "__muluna-graphics__/graphics/photometric-lab/photometric-lab-hr-emission-1.png",  frame_count = 126 },
        },
      }
      _G.data.raw.lab["cryolab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes emission layer and creates overlay and companion", function ()
      Mod.on_data_final_fixes()

      -- 3 original - 1 emission removed = 2
      assert.are.equal(2, #on_animation.layers)
      assert.are.equal("__muluna-graphics__/graphics/photometric-lab/photometric-lab-hr-shadow.png", on_animation.layers[1].filename)
      assert.are.equal("__muluna-graphics__/graphics/photometric-lab/photometric-lab-hr-animation-1.png", on_animation.layers[2].filename)

      local overlay = _G.data.raw["animation"]["mks-dsl-cryolab-overlay"]
      assert.is_not_nil(overlay)
      --- @cast overlay -nil
      assert.are.equal(
        "__disco-science-lite__/graphics/hurricane/photometric-lab-hr-overlay-1.png",
        overlay.filename
      )

      local companion = _G.data.raw["animation"]["mks-dsl-cryolab-companion"]
      assert.is_not_nil(companion)
      --- @cast companion -nil
      assert.are.equal(
        "__disco-science-lite__/graphics/hurricane/photometric-lab-hr-override-1.png",
        companion.filename
      )
    end)

    it("does not extend when emission layer is missing", function ()
      _G.data.raw.lab["cryolab"].on_animation = {
        layers = {
          { filename = "__muluna-graphics__/graphics/photometric-lab/photometric-lab-hr-animation-1.png", frame_count = 126 },
        },
      }

      Mod.on_data_final_fixes()

      assert.is_nil(_G.data.raw["animation"]["mks-dsl-cryolab-overlay"])
      assert.is_nil(_G.data.raw["animation"]["mks-dsl-cryolab-companion"])
    end)
  end)
end)
