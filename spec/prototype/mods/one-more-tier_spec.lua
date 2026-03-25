local Helper = require("spec.helper")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["one-more-tier"] = "1.0.0"
local Mod = require("scripts.prototype.mods.one-more-tier")

describe("mods/one-more-tier", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeLabRegistry.reset()
    _G.mods["one-more-tier"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers omt-lab", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["omt-lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- No public code repository
      on_animation = {
        layers = {
          { filename = "__one-more-tier__/graphics/entity/lab/lab.png",             frame_count = 33 },
          { filename = "__one-more-tier__/graphics/entity/lab/lab-integration.png", frame_count = 1, repeat_count = 33 },
          { filename = "__one-more-tier__/graphics/entity/lab/lab-light.png",       frame_count = 33 },
          { filename = "__one-more-tier__/graphics/entity/lab/lab-shadow.png",      frame_count = 1, repeat_count = 33 },
        },
      }
      _G.data.raw.lab["omt-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("applies vanilla lab modifications to omt-lab", function ()
      Mod.on_data_final_fixes()

      assert.are.equal(3, #on_animation.layers)
      assert.are.equal("__disco-science-lite__/graphics/factorio/lab-mask.png" --[[$GRAPHICS_DIR .. "factorio/lab-mask.png"]], on_animation.layers[1].filename)
      assert.are.equal("__one-more-tier__/graphics/entity/lab/lab-integration.png", on_animation.layers[2].filename)
      assert.are.equal("__one-more-tier__/graphics/entity/lab/lab-shadow.png", on_animation.layers[3].filename)
      Helper.assert_animation.frozen(1, on_animation)
    end)
  end)
end)
