--- Bob's Tech by Bobingabout
--- https://mods.factorio.com/mod/bobtech

if not mods["bobtech"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["bob-advanced-logistic-science-pack"] = { 1.0, 0.2, 0.6 },
      ["bob-science-pack-gold"]              = { 1.0, 0.3, 0.1 },
      ["bob-alien-science-pack"]             = { 1.0, 0.4, 1.0 },
      ["bob-alien-science-pack-blue"]        = { 0.4, 0.6, 1.0 },
      ["bob-alien-science-pack-orange"]      = { 1.0, 0.6, 0.4 },
      ["bob-alien-science-pack-purple"]      = { 0.6, 0.4, 1.0 },
      ["bob-alien-science-pack-yellow"]      = { 1.0, 1.0, 0.4 },
      ["bob-alien-science-pack-green"]       = { 0.4, 1.0, 0.5 },
      ["bob-alien-science-pack-red"]         = { 1.0, 0.5, 0.4 },
    })

    -- Uses the vanilla lab overlay
    PrototypeLabRegistry.register("bob-lab-2")
    PrototypeLabRegistry.register("bob-burner-lab")
    PrototypeLabRegistry.register("bob-lab-alien")
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("bob-lab-2", function (modifier)
      modifier:apply_lab_modifications({
        lab       = "__bobtech__/graphics/entity/lab/lab2.png",
        lab_light = "__bobtech__/graphics/entity/lab/lab2-light.png",
      })
    end)

    AnimationHelpers.modify_on_animation("bob-burner-lab", function (modifier)
      -- Different shape from the vanilla lab with no light layer
      modifier:freeze_animation()
    end)

    AnimationHelpers.modify_on_animation("bob-lab-alien", function (modifier)
      modifier:apply_lab_modifications({
        lab       = "__bobtech__/graphics/entity/lab/lab-alien.png",
        lab_light = "__bobtech__/graphics/entity/lab/lab-alien-light.png",
      })
    end)
  end,
}
