local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["lignumis"] = "1.0.0"
local Mod = require("scripts.prototype.mods.lignumis")

describe("mods/lignumis", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    _G.mods["lignumis"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors for steam-science-pack and wood-science-pack", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["steam-science-pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["wood-science-pack"])
    end)

    it("registers wood-lab", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["wood-lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- Source: https://git.cacklingfiend.info/cacklingfiend/lignumis/src/branch/master/lignumis/prototypes/content/wood-lab.lua#L21
      on_animation = {
        layers = {
          { filename = "__lignumis-assets__/entity/wood-lab/wood-lab.png",       width = 194, height = 174, frame_count = 33, line_length = 11 },
          { filename = "__base__/graphics/entity/lab/lab-integration.png",       width = 242, height = 162, line_length = 1,  repeat_count = 33 },
          { filename = "__lignumis-assets__/entity/wood-lab/wood-lab-light.png", width = 216, height = 194, frame_count = 33, line_length = 11,  blend_mode = "additive", draw_as_light = true },
          { filename = "__base__/graphics/entity/lab/lab-shadow.png",            width = 242, height = 136, line_length = 1,  repeat_count = 33, draw_as_shadow = true },
        },
      }
      _G.data.raw.lab["wood-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes the light layer and freezes the animation", function ()
      Mod.on_data_final_fixes()

      -- light layer removed: 4 original - 1 removed = 3
      assert.are.equal(3, #on_animation.layers)
      assert.are.equal("__lignumis-assets__/entity/wood-lab/wood-lab.png", on_animation.layers[1].filename)
      assert.are.equal("__base__/graphics/entity/lab/lab-integration.png", on_animation.layers[2].filename)
      assert.are.equal("__base__/graphics/entity/lab/lab-shadow.png", on_animation.layers[3].filename)

      -- all remaining layers are frozen
      Helper.assert_animation.frozen(1, on_animation)
    end)

    it("does not error when light layer is missing", function ()
      _G.data.raw.lab["wood-lab"].on_animation = {
        layers = {
          { filename = "__lignumis-assets__/entity/wood-lab/wood-lab.png", frame_count = 33 },
        },
      }

      assert.no_error(function () Mod.on_data_final_fixes() end)
    end)
  end)
end)
