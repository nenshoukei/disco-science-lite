local Helper = require("spec.helper")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["fusion_machines"] = "1.0.0"
local Mod = require("scripts.prototype.mods.fusion_machines")

describe("mods/fusion_machines", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeLabRegistry.reset()
    _G.mods["fusion_machines"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers labs", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["fusion-lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- Source: https://github.com/Talandar99/fusion_machines/blob/main/fusion-lab.lua#L93
      on_animation = {
        layers = {
          {
            stripes = {
              {
                filename = "__fusion_machines__/graphics/fusion_lab/fusion-lab-hr-animation-1.png",
                width_in_frames = 8,
                height_in_frames = 8,
              },
              {
                filename = "__fusion_machines__/graphics/fusion_lab/fusion-lab-hr-animation-2.png",
                width_in_frames = 8,
                height_in_frames = 2,
              },
            },
          },
          {
            stripes = {
              {
                filename = "__fusion_machines__/graphics/fusion_lab/fusion-lab-hr-emission-1.png",
                width_in_frames = 8,
                height_in_frames = 8,
              },
              {
                filename = "__fusion_machines__/graphics/fusion_lab/fusion-lab-hr-emission-2.png",
                width_in_frames = 8,
                height_in_frames = 2,
              },
            },
          },
          {
            filename = "__fusion_machines__/graphics/fusion_lab/fusion-lab-hr-shadow.png",
          },
        },
      }
      _G.data.raw.lab["fusion-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("applies lab modifications", function ()
      Mod.on_data_final_fixes()
      -- original 3 - emission 1 = 2
      assert.are.equal(2, #on_animation.layers)
      assert.are.equal("__fusion_machines__/graphics/fusion_lab/fusion-lab-hr-animation-1.png", on_animation.layers[1].stripes[1].filename)
      assert.are.equal("__fusion_machines__/graphics/fusion_lab/fusion-lab-hr-shadow.png", on_animation.layers[2].filename)
    end)

    it("creates the fusion-lab overlay animation", function ()
      Mod.on_data_final_fixes()

      local overlay = data.raw["animation"]["mks-dsl-fusion-lab-overlay"]
      assert.is_not_nil(overlay)
      assert.are.equal("__disco-science-lite__/graphics/hurricane/photometric-lab-hr-overlay-1.png", overlay.stripes[1].filename)
      assert.are.equal("__disco-science-lite__/graphics/hurricane/photometric-lab-hr-overlay-2.png", overlay.stripes[2].filename)
    end)

    it("creates the fusion-lab companion animation", function ()
      Mod.on_data_final_fixes()

      local companion = data.raw["animation"]["mks-dsl-fusion-lab-companion"]
      assert.is_not_nil(companion)
      assert.are.equal("__disco-science-lite__/graphics/hurricane/photometric-lab-hr-override-1.png", companion.stripes[1].filename)
      assert.are.equal("__disco-science-lite__/graphics/hurricane/photometric-lab-hr-override-2.png", companion.stripes[2].filename)
    end)
  end)
end)
