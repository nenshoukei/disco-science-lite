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
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["labomatic"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes (non-HD mode)", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- Source: https://github.com/StargateurFactorioMod/LabOMatic/blob/main/data.lua#L35
      _G.settings.startup["labomatic-hd"] = { value = false }
      on_animation = {
        layers = {
          { filename = "__LabOMatic__/graphics/lab_albedo_anim.png", frame_count = 29 },
          { filename = "__LabOMatic__/graphics/lab_light_anim.png",  frame_count = 29 },
          { filename = "__LabOMatic__/graphics/lab_shadow.png",      frame_count = 1, repeat_count = 29 },
          { filename = "__LabOMatic__/graphics/lab_albedo_ao.png",   frame_count = 1, repeat_count = 29 },
        },
      }
      _G.data.raw.lab["labomatic"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes the light layer and anim layer, and inserts mask layer", function ()
      Mod.on_data_final_fixes()
      -- 4 original - 1 light - 1 anim + 1 mask = 3
      assert.are.equal(3, #on_animation.layers)
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim-mask.png", on_animation.layers[1].filename)
      assert.are.equal("__LabOMatic__/graphics/lab_shadow.png", on_animation.layers[2].filename)
      assert.are.equal("__LabOMatic__/graphics/lab_albedo_ao.png", on_animation.layers[3].filename)
    end)

    it("creates the labomatic overlay animation", function ()
      Mod.on_data_final_fixes()
      local overlay = _G.data.raw["animation"]["mks-dsl-labomatic-overlay"]
      assert.is_not_nil(overlay)
      --- @cast overlay -nil
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim-overlay.png", overlay.filename)
    end)

    it("creates the labomatic companion animation", function ()
      Mod.on_data_final_fixes()
      local companion = _G.data.raw["animation"]["mks-dsl-labomatic-companion"]
      assert.is_not_nil(companion)
      --- @cast companion -nil
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim-mask.png", companion.filename)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes (HD mode)", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- Source: https://github.com/StargateurFactorioMod/LabOMatic/blob/main/data.lua#L35
      _G.settings.startup["labomatic-hd"] = { value = true }
      on_animation = {
        layers = {
          { filename = "__LabOMatic__/graphics/lab_albedo_anim_x4.png", frame_count = 29 },
          { filename = "__LabOMatic__/graphics/lab_light_anim_x4.png",  frame_count = 29 },
          { filename = "__LabOMatic__/graphics/lab_shadow_x4.png",      frame_count = 1, repeat_count = 29 },
          { filename = "__LabOMatic__/graphics/lab_albedo_ao_x4.png",   frame_count = 1, repeat_count = 29 },
        },
      }
      _G.data.raw.lab["labomatic"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes the light layer and anim layer, and inserts mask layer", function ()
      Mod.on_data_final_fixes()
      -- 4 original - 1 light - 1 anim + 1 mask = 3
      assert.are.equal(3, #on_animation.layers)
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim_x4-mask.png", on_animation.layers[1].filename)
      assert.are.equal("__LabOMatic__/graphics/lab_shadow_x4.png", on_animation.layers[2].filename)
      assert.are.equal("__LabOMatic__/graphics/lab_albedo_ao_x4.png", on_animation.layers[3].filename)
    end)

    it("creates the labomatic overlay animation", function ()
      Mod.on_data_final_fixes()
      local overlay = _G.data.raw["animation"]["mks-dsl-labomatic-overlay"]
      assert.is_not_nil(overlay)
      --- @cast overlay -nil
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim_x4-overlay.png", overlay.filename)
    end)

    it("creates the labomatic companion animation", function ()
      Mod.on_data_final_fixes()
      local companion = _G.data.raw["animation"]["mks-dsl-labomatic-companion"]
      assert.is_not_nil(companion)
      --- @cast companion -nil
      assert.are.equal("__disco-science-lite__/graphics/laborat/lab_albedo_anim_x4-mask.png", companion.filename)
    end)
  end)
end)
