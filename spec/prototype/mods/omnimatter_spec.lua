local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["omnimatter_compression"] = "1.0.0"
local Mod = require("scripts.prototype.mods.omnimatter")

describe("mods/omnimatter", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeLabRegistry.reset()
    _G.mods["omnimatter_compression"] = "1.0.0"
    _G.mods["omnimatter_science"] = "1.0.0"
    _G.mods["omnimatter_crystal"] = "1.0.0"
    _G.mods["omnimatter_energy"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers prefix for compressed science packs", function ()
      Mod.on_data()
      assert.are.same({ "compressed-" }, PrototypeColorRegistry.registered_prefixes)
    end)

    it("registers colors for science packs", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["omni-pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["production-science-pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["energy-science-pack"])
    end)

    it("registers omnitor-lab", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["omnitor-lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      Helper.load_animation_definitions()

      -- Source: https://github.com/Omnimods/Omnimods/blob/master/omnimatter_energy/prototypes/entities/burner.lua#L66
      on_animation = {
        layers = {
          { filename = "__omnimatter_energy__/graphics/entity/omnitor-lab/omnitor-lab.png", frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-integration.png",                  frame_count = 1, repeat_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-light.png",                        frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-shadow.png",                       frame_count = 1, repeat_count = 33 },
        },
      }
      _G.data.raw.lab["omnitor-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes the light layer, freezes animation, and creates overlay", function ()
      Mod.on_data_final_fixes()

      assert.are.equal(3, #on_animation.layers)
      assert.are.equal("__omnimatter_energy__/graphics/entity/omnitor-lab/omnitor-lab.png", on_animation.layers[1].filename)
      assert.are.equal("__base__/graphics/entity/lab/lab-integration.png", on_animation.layers[2].filename)
      assert.are.equal("__base__/graphics/entity/lab/lab-shadow.png", on_animation.layers[3].filename)
      Helper.assert_animation.frozen(1, on_animation)

      local overlay = _G.data.raw["animation"][ "mks-dsl-omnitor-lab-overlay" --[[$NAME_PREFIX .. "omnitor-lab-overlay"]] ]
      assert.is_not_nil(overlay) --- @cast overlay -nil
      assert.are.equal("__disco-science-lite__/graphics/factorio/aai-burner-lab-overlay.png", overlay.filename)
    end)
  end)
end)
