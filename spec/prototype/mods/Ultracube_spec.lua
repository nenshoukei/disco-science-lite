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
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["cube-basic-contemplation-unit"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["cube-fundamental-comprehension-card"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["cube-abstract-interrogation-card"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["cube-deep-introspection-card"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["cube-synthetic-premonition-card"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["cube-complete-annihilation-card"])
    end)

    it("registers labs", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["cube-lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- Source: https://github.com/grandseiken/factorio-ultracube/blob/main/prototypes/entities/lab.lua#L24
      on_animation = {
        layers = {
          { filename = "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-anim-light.png", frame_count = 29 },
          { filename = "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-anim.png",       frame_count = 29 },
          { filename = "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-anim.png",       frame_count = 29 },
          { filename = "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-anim.png",       frame_count = 29 },
          { filename = "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-light-anim.png", frame_count = 29 },
          { filename = "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-light-anim.png", frame_count = 29 },
          { filename = "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-shadow.png",     frame_count = 1, repeat_count = 29 },
          { filename = "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-ao.png",         frame_count = 1, repeat_count = 29 },
        },
      }
      _G.data.raw.lab["cube-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("applies lab modifications", function ()
      Mod.on_data_final_fixes()
      -- 8 original - 2 light-anim layers - 3 anim layers + 1 mask inserted = 4
      assert.are.equal(4, #on_animation.layers)
      assert.are.equal("__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-anim-light.png", on_animation.layers[1].filename)
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim-mask.png", on_animation.layers[2].filename)
      assert.are.equal("__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-shadow.png", on_animation.layers[3].filename)
      assert.are.equal("__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-ao.png", on_animation.layers[4].filename)
    end)

    it("creates the cube-lab overlay animation", function ()
      Mod.on_data_final_fixes()
      local overlay = _G.data.raw["animation"]["mks-dsl-cube-lab-overlay"]
      assert.is_not_nil(overlay)
      --- @cast overlay -nil
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim-overlay.png", overlay.filename)
    end)

    it("creates the cube-lab companion animation", function ()
      Mod.on_data_final_fixes()
      local companion = _G.data.raw["animation"]["mks-dsl-cube-lab-companion"]
      assert.is_not_nil(companion)
      --- @cast companion -nil
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim-mask.png", companion.filename)
    end)
  end)
end)
