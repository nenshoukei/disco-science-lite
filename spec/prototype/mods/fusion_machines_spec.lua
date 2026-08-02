local assert = require("luassert")
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
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["fusion-lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    --- @type data.Animation
    local on_animation

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
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()
      -- original 3 - emission 1 = 2
      assert.are.equal(2, #on_animation.layers) --- @cast on_animation.layers - nil
      --- @diagnostic disable-next-line: need-check-nil
      assert.are.equal("__fusion_machines__/graphics/fusion_lab/fusion-lab-hr-animation-1.png", on_animation.layers[1].stripes[1].filename)
      --- @diagnostic disable-next-line: need-check-nil
      assert.are.equal("__fusion_machines__/graphics/fusion_lab/fusion-lab-hr-shadow.png", on_animation.layers[2].filename)
    end)

    it("creates the fusion-lab overlay animation", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      local overlay = data.raw["animation"]["mks-dsl-fusion-lab-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay - nil
      assert.is_not_nil(overlay.stripes) --- @cast overlay.stripes - nil
      assert.are.equal("__disco-science-lite__/graphics/hurricane/photometric-lab-hr-overlay-1.png", overlay.stripes[1] and overlay.stripes[1].filename)
      assert.are.equal("__disco-science-lite__/graphics/hurricane/photometric-lab-hr-overlay-2.png", overlay.stripes[2] and overlay.stripes[2].filename)
    end)

    it("creates the fusion-lab companion animation", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      local companion = data.raw["animation"]["mks-dsl-fusion-lab-companion"]
      assert.is_not_nil(companion) --- @cast companion - nil
      assert.is_not_nil(companion.stripes) --- @cast companion.stripes - nil
      assert.are.equal("__disco-science-lite__/graphics/hurricane/photometric-lab-hr-override-1.png", companion.stripes[1] and companion.stripes[1].filename)
      assert.are.equal("__disco-science-lite__/graphics/hurricane/photometric-lab-hr-override-2.png", companion.stripes[2] and companion.stripes[2].filename)
    end)
  end)
end)
