local assert = require("luassert")
local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["skewer_shattered_planet"] = "1.0.0"
local Mod = require("scripts.prototype.mods.skewer_shattered_planet")

describe("mods/skewer_shattered_planet", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    _G.mods["skewer_shattered_planet"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["ske_heu_science_pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["ske_hep_science_pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["ske_hea_science_pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["ske_hec_science_pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["ske_hef_science_pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["ske_antimatter_cell"])
    end)

    it("registers labs", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["pearl_realizer"])
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
          { filename = "__space-exploration-graphics-4__/graphics/entity/gravimetrics-laboratory/gravimetrics-laboratory-shadow.png" },
          { filename = "__space-exploration-graphics-4__/graphics/entity/gravimetrics-laboratory/gravimetrics-laboratory.png" },
          { filename = "__space-exploration-graphics-4__/graphics/entity/gravimetrics-laboratory/gravimetrics-laboratory-tint.png" },
        },
      }
      _G.data.raw.lab["pearl_realizer"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("applies lab modifications", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      Helper.assert_animation.has_layers({
        "__space-exploration-graphics-4__/graphics/entity/gravimetrics-laboratory/gravimetrics-laboratory-shadow.png",
      }, on_animation)
    end)

    it("creates overlay animation", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()
      local overlay = data.raw.animation["mks-dsl-pearl-realizer-overlay"]
      assert.is_not_nil(overlay)
    end)

    it("creates companion animation", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()
      local companion = data.raw.animation["mks-dsl-pearl-realizer-companion"]
      assert.is_not_nil(companion)
    end)
  end)
end)
