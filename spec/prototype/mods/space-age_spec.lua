local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["space-age"] = "1.0.0"
local Mod = require("scripts.prototype.mods.space-age")

describe("mods/space-age", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    _G.mods["space-age"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors for science packs", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["agricultural-science-pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["promethium-science-pack"])
    end)

    it("registers biolab", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["biolab"])
    end)

    it("creates biolab overlay animation", function ()
      Mod.on_data()
      local overlay = _G.data.raw["animation"]["mks-dsl-biolab-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay -nil
      assert.are.equal("__disco-science-lite__/graphics/factorio/biolab-overlay.png", overlay.filename)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- Source: https://github.com/wube/factorio-data/blob/master/space-age/prototypes/entity/entities.lua#L1607
      on_animation = {
        layers = {
          { filename = "__space-age__/graphics/entity/biolab/biolab-anim.png",   frame_count = 32 },
          { filename = "__space-age__/graphics/entity/biolab/biolab-lights.png", frame_count = 32 },
          { filename = "__space-age__/graphics/entity/biolab/biolab-shadow.png", frame_count = 32 },
        },
      }
      _G.data.raw.lab["biolab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes the biolab lights layer from on_animation", function ()
      Mod.on_data_final_fixes()

      assert.are.equal(2, #on_animation.layers)
      assert.are.equal("__space-age__/graphics/entity/biolab/biolab-anim.png", on_animation.layers[1].filename)
      assert.are.equal("__space-age__/graphics/entity/biolab/biolab-shadow.png", on_animation.layers[2].filename)
    end)
  end)
end)
