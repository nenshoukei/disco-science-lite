local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local Mod = require("scripts.prototype.mods.base")

describe("mods/base", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    -- No mod guard in base.lua, so no mod key is set here.
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors for all vanilla science packs", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["automation-science-pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["logistic-science-pack"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["space-science-pack"])
    end)

    it("registers lab", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- Source: https://github.com/wube/factorio-data/blob/master/base/prototypes/entity/entities.lua#L3830
      on_animation = {
        layers = {
          { filename = "__base__/graphics/entity/lab/lab.png",             frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-integration.png", frame_count = 1, repeat_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-light.png",       frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-shadow.png",      frame_count = 1, repeat_count = 33 },
        },
      }
      _G.data.raw.lab["lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes light layer and freezes remaining layers", function ()
      Mod.on_data_final_fixes()

      assert.are.equal(3, #on_animation.layers)
      assert.are.equal("__base__/graphics/entity/lab/lab.png", on_animation.layers[1].filename)
      assert.are.equal("__base__/graphics/entity/lab/lab-integration.png", on_animation.layers[2].filename)
      assert.are.equal("__base__/graphics/entity/lab/lab-shadow.png", on_animation.layers[3].filename)
      Helper.assert_animation.frozen(1, on_animation)
    end)

    it("does nothing when lab is not in data.raw", function ()
      _G.data.raw.lab["lab"] = nil

      assert.no_error(function ()
        Mod.on_data_final_fixes()
      end)
    end)
  end)
end)
