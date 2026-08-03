local assert = require("luassert")
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
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["kr-blank-tech-card"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["kr-singularity-tech-card"])
    end)

    it("registers kr-advanced-lab", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["kr-advanced-lab"])
    end)

    it("registers kr-singularity-lab", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["kr-singularity-lab"])
    end)

    it("registers electromagnetic-science-pack color when Krastorio2-spaced-out is also active", function ()
      _G.mods["Krastorio2-spaced-out"] = "1.0.0"
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["electromagnetic-science-pack"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes - kr-advanced-lab", function ()
    --- @type data.Animation
    local on_animation

    before_each(function ()
      -- Source: https://codeberg.org/raiguard/Krastorio2/src/branch/trunk/prototypes/buildings/advanced-lab.lua#L63
      on_animation = {
        layers = {
          { filename = "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-anim-light.png", frame_count = 29 },
          { filename = "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-anim.png", frame_count = 29 },
          { filename = "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-anim.png", frame_count = 29 },
          { filename = "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-anim.png", frame_count = 29 },
          { filename = "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-light-anim.png", frame_count = 29 },
          { filename = "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-light-anim.png", frame_count = 29 },
          { filename = "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-shadow.png", frame_count = 1, repeat_count = 29 },
          { filename = "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-ao.png", frame_count = 1, repeat_count = 29 },
        },
      }
      _G.data.raw.lab["kr-advanced-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes light layers and anim layers, and inserts mask layer", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      Helper.assert_animation.has_layers({
        "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-anim-light.png",
        "__disco-science-lite__/graphics/laborat/lab_albedo_anim-mask.png",
        "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-shadow.png",
        "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-ao.png",
      }, on_animation)
    end)

    it("creates the kr-advanced-lab overlay animation", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()
      local overlay = _G.data.raw["animation"]["mks-dsl-kr-advanced-lab-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay - nil
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim-overlay.png", overlay.filename)
    end)

    it("creates the kr-advanced-lab companion animation", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()
      local companion = _G.data.raw["animation"]["mks-dsl-kr-advanced-lab-companion"]
      assert.is_not_nil(companion) --- @cast companion - nil
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim-mask.png", companion.filename)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes - kr-singularity-lab", function ()
    --- @type data.Animation
    local on_animation

    before_each(function ()
      -- Source: https://codeberg.org/raiguard/Krastorio2/src/branch/trunk/prototypes/buildings/singularity-lab.lua#L69
      on_animation = {
        layers = {
          { filename = "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-glow-light.png", frame_count = 60 },
          { filename = "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-glow.png", frame_count = 60 },
          { filename = "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-light.png", frame_count = 1, repeat_count = 60 },
          { filename = "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-working.png", frame_count = 60 },
          { filename = "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-sh.png", frame_count = 1, repeat_count = 60 },
        },
      }
      _G.data.raw.lab["kr-singularity-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes the glow layer and inserts a mask layer", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      Helper.assert_animation.has_layers({
        "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-glow-light.png",
        "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-light.png",
        "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-working.png",
        "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-glow-light.png",
        "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-sh.png",
      }, on_animation)
    end)

    it("creates the kr-singularity-lab overlay animation", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()
      local overlay = _G.data.raw["animation"]["mks-dsl-kr-singularity-lab-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay - nil
      assert.are.equal("__disco-science-lite__/graphics/Krastorio2/singularity-lab-overlay.png", overlay.filename)
    end)
  end)
end)
