local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["Krastorio2"] = "1.0.0"
local Mod = require("scripts.prototype.mods.Krastorio2")

describe("mods/Krastorio2", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    _G.mods["Krastorio2"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors for Krastorio2 science packs", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["kr-blank-tech-card"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["kr-singularity-tech-card"])
    end)

    it("registers kr-advanced-lab", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["kr-advanced-lab"])
    end)

    it("registers kr-singularity-lab", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["kr-singularity-lab"])
    end)

    it("registers electromagnetic-science-pack color when Krastorio2-spaced-out is also active", function ()
      _G.mods["Krastorio2-spaced-out"] = "1.0.0"
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["electromagnetic-science-pack"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes - kr-advanced-lab", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- Source: https://codeberg.org/raiguard/Krastorio2/src/branch/trunk/prototypes/buildings/advanced-lab.lua#L63
      on_animation = {
        layers = {
          { filename = "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-anim-light.png", frame_count = 29 },
          { filename = "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-anim.png",       frame_count = 29 },
          { filename = "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-anim.png",       frame_count = 29 },
          { filename = "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-anim.png",       frame_count = 29 },
          { filename = "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-light-anim.png", frame_count = 29 },
          { filename = "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-light-anim.png", frame_count = 29 },
          { filename = "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-shadow.png",     frame_count = 1, repeat_count = 29 },
          { filename = "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-ao.png",         frame_count = 1, repeat_count = 29 },
        },
      }
      _G.data.raw.lab["kr-advanced-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes light layers and anim layers, and inserts mask layer", function ()
      Mod.on_data_final_fixes()
      -- 8 original - 2 light-anim layers - 3 anim layers + 1 mask inserted = 4
      assert.are.equal(4, #on_animation.layers)
      assert.are.equal("__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-anim-light.png", on_animation.layers[1].filename)
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim-mask.png", on_animation.layers[2].filename)
      assert.are.equal("__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-shadow.png", on_animation.layers[3].filename)
      assert.are.equal("__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-ao.png", on_animation.layers[4].filename)
    end)

    it("creates the kr-advanced-lab overlay animation", function ()
      Mod.on_data_final_fixes()
      local overlay = _G.data.raw["animation"]["mks-dsl-kr-advanced-lab-overlay"]
      assert.is_not_nil(overlay)
      --- @cast overlay -nil
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim-overlay.png", overlay.filename)
    end)

    it("creates the kr-advanced-lab companion animation", function ()
      Mod.on_data_final_fixes()
      local companion = _G.data.raw["animation"]["mks-dsl-kr-advanced-lab-companion"]
      assert.is_not_nil(companion)
      --- @cast companion -nil
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim-mask.png", companion.filename)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes - kr-singularity-lab", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- Source: https://codeberg.org/raiguard/Krastorio2/src/branch/trunk/prototypes/buildings/singularity-lab.lua#L69
      on_animation = {
        layers = {
          { filename = "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-glow-light.png", frame_count = 60 },
          { filename = "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-glow.png",       frame_count = 60 },
          { filename = "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-light.png",      frame_count = 1, repeat_count = 60 },
          { filename = "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-working.png",    frame_count = 60 },
          { filename = "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-sh.png",         frame_count = 1, repeat_count = 60 },
        },
      }
      _G.data.raw.lab["kr-singularity-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes the glow layer and inserts a mask layer", function ()
      Mod.on_data_final_fixes()
      -- 5 original - 1 glow layer + 1 mask inserted = 5
      assert.are.equal(5, #on_animation.layers)
      assert.are.equal("__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-glow-light.png", on_animation.layers[1].filename)
      assert.are.equal("__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-working.png", on_animation.layers[3].filename)
    end)

    it("creates the kr-singularity-lab overlay animation", function ()
      Mod.on_data_final_fixes()
      local overlay = _G.data.raw["animation"]["mks-dsl-kr-singularity-lab-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay -nil
      assert.are.equal("__disco-science-lite__/graphics/Krastorio2/singularity-lab-overlay.png", overlay.filename)
    end)
  end)
end)
