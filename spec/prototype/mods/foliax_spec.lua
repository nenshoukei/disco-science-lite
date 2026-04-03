local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["foliax"] = "1.0.0"
local Mod = require("scripts.prototype.mods.foliax")

describe("mods/foliax", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    _G.mods["foliax"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["foliax-research-transportation"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["foliax-research-machine"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["foliax-research-biology"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["foliax-research-power"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["foliax-research-optimization"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["foliax-research-violence"])
    end)

    it("registers labs", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["foliax-burner-biolab"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["foliax-burner-biolab-mk2"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation_foliax_burner_biolab     --- @type data.Animation
    local on_animation_foliax_burner_biolab_mk2 --- @type data.Animation

    before_each(function ()
      -- No public code repositories
      on_animation_foliax_burner_biolab = {
        layers = {
          { filename = "__space-age__/graphics/entity/biolab/biolab-anim.png" },
          { filename = "__cr-commons__/graphics/entity/biolab/biolab-color-mask.png" },
          { filename = "__cr-commons__/graphics/entity/biolab/biolab-light-mask.png" },
          { filename = "__space-age__/graphics/entity/biolab/biolab-lights.png" },
          { filename = "__space-age__/graphics/entity/biolab/biolab-shadow.png" },
        },
      }
      -- No public code repositories
      on_animation_foliax_burner_biolab_mk2 = {
        layers = {
          { filename = "__space-age__/graphics/entity/biolab/biolab-anim.png" },
          { filename = "__cr-commons__/graphics/entity/biolab/biolab-color-mask.png" },
          { filename = "__cr-commons__/graphics/entity/biolab/biolab-light-mask.png" },
          { filename = "__space-age__/graphics/entity/biolab/biolab-lights.png" },
          { filename = "__space-age__/graphics/entity/biolab/biolab-shadow.png" },
        },
      }
      _G.data.raw.lab["foliax-burner-biolab"] = ({ on_animation = on_animation_foliax_burner_biolab }) --[[@as data.LabPrototype]]
      _G.data.raw.lab["foliax-burner-biolab-mk2"] = ({ on_animation = on_animation_foliax_burner_biolab_mk2 }) --[[@as data.LabPrototype]]
    end)

    it("applies lab modifications to foliax-burner-biolab", function ()
      Mod.on_data_final_fixes()
      -- 5 original - 1 light = 4
      assert.are.equal(4, #on_animation_foliax_burner_biolab.layers)
      assert.are.equal("__space-age__/graphics/entity/biolab/biolab-anim.png", on_animation_foliax_burner_biolab.layers[1].filename)
      assert.are.equal("__cr-commons__/graphics/entity/biolab/biolab-color-mask.png", on_animation_foliax_burner_biolab.layers[2].filename)
      assert.are.equal("__cr-commons__/graphics/entity/biolab/biolab-light-mask.png", on_animation_foliax_burner_biolab.layers[3].filename)
      assert.are.equal("__space-age__/graphics/entity/biolab/biolab-shadow.png", on_animation_foliax_burner_biolab.layers[4].filename)
    end)

    it("applies lab modifications to foliax-burner-biolab-mk2", function ()
      Mod.on_data_final_fixes()
      -- 5 original - 1 light = 4
      assert.are.equal(4, #on_animation_foliax_burner_biolab_mk2.layers)
      assert.are.equal("__space-age__/graphics/entity/biolab/biolab-anim.png", on_animation_foliax_burner_biolab_mk2.layers[1].filename)
      assert.are.equal("__cr-commons__/graphics/entity/biolab/biolab-color-mask.png", on_animation_foliax_burner_biolab_mk2.layers[2].filename)
      assert.are.equal("__cr-commons__/graphics/entity/biolab/biolab-light-mask.png", on_animation_foliax_burner_biolab_mk2.layers[3].filename)
      assert.are.equal("__space-age__/graphics/entity/biolab/biolab-shadow.png", on_animation_foliax_burner_biolab_mk2.layers[4].filename)
    end)
  end)
end)
