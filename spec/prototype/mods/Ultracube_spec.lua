local assert = require("luassert")
local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["Ultracube"] = "1.0.0"
local Mod = require("scripts.prototype.mods.Ultracube")

describe("mods/Ultracube", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    _G.mods["Ultracube"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["cube-basic-contemplation-unit"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["cube-fundamental-comprehension-card"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["cube-abstract-interrogation-card"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["cube-deep-introspection-card"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["cube-synthetic-premonition-card"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["cube-complete-annihilation-card"])
    end)

    it("registers labs", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["cube-lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    --- @type data.Animation
    local on_animation

    before_each(function ()
      -- Source: https://github.com/grandseiken/factorio-ultracube/blob/main/prototypes/entities/lab.lua#L24
      on_animation = {
        layers = {
          { filename = "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-anim-light.png", frame_count = 29 },
          { filename = "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-anim.png", frame_count = 29 },
          { filename = "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-anim.png", frame_count = 29 },
          { filename = "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-anim.png", frame_count = 29 },
          { filename = "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-light-anim.png", frame_count = 29 },
          { filename = "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-light-anim.png", frame_count = 29 },
          { filename = "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-shadow.png", frame_count = 1, repeat_count = 29 },
          { filename = "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-ao.png", frame_count = 1, repeat_count = 29 },
        },
      }
      _G.data.raw.lab["cube-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("applies lab modifications", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      Helper.assert_animation.has_layers({
        "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-anim-light.png",
        "__disco-science-lite__/graphics/laborat/lab_albedo_anim-mask.png",
        "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-shadow.png",
        "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-ao.png",
      }, on_animation)
    end)

    it("creates the cube-lab overlay animation", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()
      local overlay = _G.data.raw["animation"]["mks-dsl-cube-lab-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay - nil
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim-overlay.png", overlay.filename)
    end)

    it("creates the cube-lab companion animation", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()
      local companion = _G.data.raw["animation"]["mks-dsl-cube-lab-companion"]
      assert.is_not_nil(companion) --- @cast companion - nil
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim-mask.png", companion.filename)
    end)
  end)
end)
