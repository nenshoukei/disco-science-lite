local assert = require("luassert")
local Helper = require("spec.helper")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["aai-industry"] = "1.0.0"
local Mod = require("scripts.prototype.mods.aai-industry")

describe("mods/aai-industry", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeLabRegistry.reset()
    _G.mods["aai-industry"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers burner-lab", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["burner-lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    --- @type data.Animation
    local on_animation

    before_each(function ()
      Helper.load_animation_definitions()

      -- No public code repositories
      on_animation = {
        layers = {
          { filename = "__aai-industry__/graphics/entity/burner-lab/burner-lab.png", frame_count = 33 },
          { filename = "__aai-industry__/graphics/entity/burner-lab/burner-lab-light.png", frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-integration.png", frame_count = 1, repeat_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-shadow.png", frame_count = 1, repeat_count = 33 },
        },
      }
      _G.data.raw.lab["burner-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes the light layer, freezes animation, and creates overlay", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      Helper.assert_animation.has_layers({
        "__aai-industry__/graphics/entity/burner-lab/burner-lab.png",
        "__base__/graphics/entity/lab/lab-integration.png",
        "__base__/graphics/entity/lab/lab-shadow.png",
      }, on_animation)

      Helper.assert_animation.frozen(1, on_animation)

      local overlay = _G.data.raw["animation"]["mks-dsl-burner-lab-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay - nil
      assert.are.equal("__disco-science-lite__/graphics/factorio/aai-burner-lab-overlay.png", overlay.filename)
    end)
  end)
end)
