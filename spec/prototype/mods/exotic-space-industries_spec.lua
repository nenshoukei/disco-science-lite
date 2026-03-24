local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["exotic-space-industries"] = "1.0.0"
local Mod = require("scripts.prototype.mods.exotic-space-industries")

describe("mods/exotic-space-industries", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    _G.mods["exotic-space-industries"] = "1.0.0"
  end)

  describe("remembrance", function ()
    it("is supported", function ()
      _G.mods["exotic-space-industries"] = nil
      _G.mods["exotic-space-industries-remembrance"] = "1.0.0"
      package.loaded["scripts.prototype.mods.exotic-space-industries"] = nil
      local mod = require("scripts.prototype.mods.exotic-space-industries")
      assert.is_function(mod.on_data)
      assert.is_function(mod.on_data_final_fixes)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors for ESI science packs", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["ei-dark-age-tech"])
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["ei-quantum-age-tech"])
    end)

    it("registers ei-dark-age-lab", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["ei-dark-age-lab"])
    end)

    it("excludes ei-big-lab", function ()
      Mod.on_data()
      assert.is_true(PrototypeLabRegistry.excluded_labs["ei-big-lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- No public code repository for ESI
      -- ESI Remembrance Source: https://github.com/aRighteousGod/exotic-space-industries-remembrance/blob/master/exotic-space-industries-remembrance/prototypes/dark-age/lab.lua#L47
      on_animation = {
        layers = {
          { filename = "__exotic-space-industries-remembrance__/graphics/entities/dark-age-lab_animation.png", frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-integration.png",                                     frame_count = 1, repeat_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-light.png",                                           frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-shadow.png",                                          frame_count = 1, repeat_count = 33 },
        },
      }
      _G.data.raw.lab["ei-dark-age-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes light layer and freezes ei-dark-age-lab", function ()
      Mod.on_data_final_fixes()

      assert.are.equal(3, #on_animation.layers)
      assert.are.equal("__exotic-space-industries-remembrance__/graphics/entities/dark-age-lab_animation.png", on_animation.layers[1].filename)
      assert.are.equal("__base__/graphics/entity/lab/lab-integration.png", on_animation.layers[2].filename)
      assert.are.equal("__base__/graphics/entity/lab/lab-shadow.png", on_animation.layers[3].filename)
      Helper.assert_animation.frozen(1, on_animation)
    end)

    it("does nothing when lab is not in data.raw", function ()
      _G.data.raw.lab["ei-dark-age-lab"] = nil

      assert.no_error(function ()
        Mod.on_data_final_fixes()
      end)
    end)
  end)
end)
