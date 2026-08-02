local assert = require("luassert")
local Helper = require("spec.helper")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["fusion-lab"] = "1.0.0"
local Mod = require("scripts.prototype.mods.fusion-lab")

describe("mods/fusion-lab", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeLabRegistry.reset()
    _G.mods["fusion-lab"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers fusion-lab", function ()
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
      -- No public code repository
      on_animation = {
        layers = {
          { filename = "__fusion-lab__/graphics/entity/fusion-lab/photometric-lab-hr-shadow.png", frame_count = 1, repeat_count = 80 },
          {
            filenames = {
              "__fusion-lab__/graphics/entity/fusion-lab/photometric-lab-hr-animation-1.png",
              "__fusion-lab__/graphics/entity/fusion-lab/photometric-lab-hr-animation-2.png",
            },
            frame_count = 80,
          },
          {
            filenames = {
              "__fusion-lab__/graphics/entity/fusion-lab/photometric-lab-hr-emission-1.png",
              "__fusion-lab__/graphics/entity/fusion-lab/photometric-lab-hr-emission-2.png",
            },
            frame_count = 80,
          },
        },
      }
      _G.data.raw.lab["fusion-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes the emission layer and creates overlay and companion", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      assert.are.equal(2, #on_animation.layers)
      --- @diagnostic disable-next-line: need-check-nil
      assert.are.equal("__fusion-lab__/graphics/entity/fusion-lab/photometric-lab-hr-shadow.png", on_animation.layers[1].filename)
      --- @diagnostic disable-next-line: need-check-nil
      assert.are.equal("__fusion-lab__/graphics/entity/fusion-lab/photometric-lab-hr-animation-1.png", on_animation.layers[2].filenames[1])

      local overlay = _G.data.raw["animation"]["mks-dsl-fusion-lab-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay - nil
      assert.is_not_nil(overlay.filenames) --- @cast overlay.filenames - nil
      assert.are.equal(
        "__disco-science-lite__/graphics/hurricane/photometric-lab-hr-overlay-1.png",
        overlay.filenames[1]
      )

      local companion = _G.data.raw["animation"]["mks-dsl-fusion-lab-companion"]
      assert.is_not_nil(companion) --- @cast companion - nil
      assert.is_not_nil(companion.filenames) --- @cast companion.filenames - nil
      assert.are.equal(
        "__disco-science-lite__/graphics/hurricane/photometric-lab-hr-override-1.png",
        companion.filenames[1]
      )
    end)

    it("does not extend when emission layer is missing", function ()
      _G.data.raw.lab["fusion-lab"].on_animation = {
        layers = {
          { filename = "__fusion-lab__/graphics/entity/fusion-lab/photometric-lab-hr-animation-1.png", frame_count = 64 },
        },
      }

      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      assert.is_nil(_G.data.raw["animation"]["mks-dsl-fusion-lab-overlay"])
      assert.is_nil(_G.data.raw["animation"]["mks-dsl-fusion-lab-companion"])
    end)
  end)
end)
