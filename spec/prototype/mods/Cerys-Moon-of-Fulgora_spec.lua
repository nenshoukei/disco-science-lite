local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["Cerys-Moon-of-Fulgora"] = "1.0.0"
local Mod = require("scripts.prototype.mods.Cerys-Moon-of-Fulgora")

describe("mods/Cerys-Moon-of-Fulgora", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    _G.mods["Cerys-Moon-of-Fulgora"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers color for cerysian-science-pack", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors["cerysian-science-pack"])
    end)

    it("registers cerys-lab", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["cerys-lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      Helper.load_animation_definitions()

      -- Source: https://github.com/danielmartin0/Cerys-Moon-of-Fulgora/blob/main/prototypes/entity/lab.lua#L26
      on_animation = {
        layers = {
          { filename = "__Cerys-Moon-of-Fulgora__/graphics/entity/cerys-lab/cerys-lab-back.png",         repeat_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab.png",                                           frame_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-integration.png",                               repeat_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-light.png",                                     frame_count = 33, scale = 0.5 },
          { filename = "__Cerys-Moon-of-Fulgora__/graphics/entity/cerys-lab/cerys-lab-front-shadow.png", repeat_count = 33 },
          { filename = "__Cerys-Moon-of-Fulgora__/graphics/entity/cerys-lab/cerys-lab-front.png",        repeat_count = 33 },
          { filename = "__base__/graphics/entity/lab/lab-shadow.png",                                    repeat_count = 33 },
          { filename = "__Cerys-Moon-of-Fulgora__/graphics/entity/cerys-lab/cerys-lab-shadow.png",       repeat_count = 33 },
        },
      }
      _G.data.raw.lab["cerys-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("removes light/front-shadow/front layers, freezes animation, and creates overlay and companion", function ()
      Mod.on_data_final_fixes()

      assert.are.equal(5, #on_animation.layers)
      assert.are.equal("__Cerys-Moon-of-Fulgora__/graphics/entity/cerys-lab/cerys-lab-back.png", on_animation.layers[1].filename)
      assert.are.equal("__disco-science-lite__/graphics/factorio/lab-mask.png" --[[$GRAPHICS_DIR .. "factorio/lab-mask.png"]], on_animation.layers[2].filename)
      assert.are.equal("__base__/graphics/entity/lab/lab-integration.png", on_animation.layers[3].filename)
      assert.are.equal("__base__/graphics/entity/lab/lab-shadow.png", on_animation.layers[4].filename)
      assert.are.equal("__Cerys-Moon-of-Fulgora__/graphics/entity/cerys-lab/cerys-lab-shadow.png", on_animation.layers[5].filename)
      Helper.assert_animation.frozen(1, on_animation)

      local overlay = _G.data.raw["animation"]["mks-dsl-cerys-lab-overlay"]
      assert.is_not_nil(overlay)

      local companion = _G.data.raw["animation"]["mks-dsl-cerys-lab-companion"]
      assert.is_not_nil(companion) --- @cast companion -nil
      assert.are.equal(2, #companion.layers)
    end)

    it("does not extend when any required layer is missing", function ()
      -- Only the base lab layer is present; light/front-shadow/front are all missing.
      _G.data.raw.lab["cerys-lab"].on_animation = {
        layers = {
          { filename = "__base__/graphics/entity/lab/lab.png" },
        },
      }

      Mod.on_data_final_fixes()

      assert.is_nil(_G.data.raw["animation"]["mks-dsl-cerys-lab-overlay"])
      assert.is_nil(_G.data.raw["animation"]["mks-dsl-cerys-lab-companion"])
    end)
  end)
end)
