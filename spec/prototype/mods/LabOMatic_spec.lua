local assert = require("luassert")
local Helper = require("spec.helper")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["LabOMatic"] = "1.0.0"
local Mod = require("scripts.prototype.mods.LabOMatic")

describe("mods/LabOMatic", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeLabRegistry.reset()
    _G.mods["LabOMatic"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers labomatic", function ()
      assert.is_not_nil(Mod.on_data) --- @cast Mod.on_data - nil
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["labomatic"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes (non-HD mode)", function ()
    --- @type data.Animation
    local on_animation

    before_each(function ()
      -- Source: https://github.com/StargateurFactorioMod/LabOMatic/blob/main/data.lua#L35
      _G.settings.startup["labomatic-hd"] = { value = false }
      on_animation = {
        layers = {
          { filename = "__LabOMatic__/graphics/lab_albedo_anim.png", frame_count = 29 },
          { filename = "__LabOMatic__/graphics/lab_light_anim.png", frame_count = 29 },
          { filename = "__LabOMatic__/graphics/lab_shadow.png", frame_count = 1, repeat_count = 29 },
          { filename = "__LabOMatic__/graphics/lab_albedo_ao.png", frame_count = 1, repeat_count = 29 },
        },
      }
      _G.data.raw.lab["labomatic"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes the light layer and anim layer, and inserts mask layer", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      Helper.assert_animation.has_layers({
        "__disco-science-lite__/graphics/laborat/lab_albedo_anim-mask.png",
        "__LabOMatic__/graphics/lab_shadow.png",
        "__LabOMatic__/graphics/lab_albedo_ao.png",
      }, on_animation)
    end)

    it("creates the labomatic overlay animation", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()
      local overlay = _G.data.raw["animation"]["mks-dsl-labomatic-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay - nil
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim-overlay.png", overlay.filename)
    end)

    it("creates the labomatic companion animation", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()
      local companion = _G.data.raw["animation"]["mks-dsl-labomatic-companion"]
      assert.is_not_nil(companion) --- @cast companion - nil
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim-mask.png", companion.filename)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes (HD mode)", function ()
    --- @type data.Animation
    local on_animation

    before_each(function ()
      -- Source: https://github.com/StargateurFactorioMod/LabOMatic/blob/main/data.lua#L35
      _G.settings.startup["labomatic-hd"] = { value = true }
      on_animation = {
        layers = {
          { filename = "__LabOMatic__/graphics/lab_albedo_anim_x4.png", frame_count = 29 },
          { filename = "__LabOMatic__/graphics/lab_light_anim_x4.png", frame_count = 29 },
          { filename = "__LabOMatic__/graphics/lab_shadow_x4.png", frame_count = 1, repeat_count = 29 },
          { filename = "__LabOMatic__/graphics/lab_albedo_ao_x4.png", frame_count = 1, repeat_count = 29 },
        },
      }
      _G.data.raw.lab["labomatic"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes the light layer and anim layer, and inserts mask layer", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()

      Helper.assert_animation.has_layers({
        "__disco-science-lite__/graphics/laborat/lab_albedo_anim_x4-mask.png",
        "__LabOMatic__/graphics/lab_shadow_x4.png",
        "__LabOMatic__/graphics/lab_albedo_ao_x4.png",
      }, on_animation)
    end)

    it("creates the labomatic overlay animation", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()
      local overlay = _G.data.raw["animation"]["mks-dsl-labomatic-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay - nil
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim_x4-overlay.png", overlay.filename)
    end)

    it("creates the labomatic companion animation", function ()
      assert.is_not_nil(Mod.on_data_final_fixes) --- @cast Mod.on_data_final_fixes - nil
      Mod.on_data_final_fixes()
      local companion = _G.data.raw["animation"]["mks-dsl-labomatic-companion"]
      assert.is_not_nil(companion) --- @cast companion - nil
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim_x4-mask.png", companion.filename)
    end)
  end)
end)
