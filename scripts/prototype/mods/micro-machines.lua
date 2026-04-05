--- Micro Machines Mod by Kryzeth
--- https://mods.factorio.com/mod/micro-machines

if not mods["micro-machines"] then return {} end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeLabRegistry.register("micro-lab-1", {
      scale = 1 / 3,
    })
    PrototypeLabRegistry.register("micro-biolab-1", {
      animation = "mks-dsl-biolab-overlay" --[[$NAME_PREFIX .. "biolab-overlay"]],
      scale = 1 / 5,
    })
    PrototypeLabRegistry.register("micro-alien-lab-1", {
      scale = 1 / 3,
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("micro-lab-1", function (modifier)
      modifier:apply_lab_modifications()
    end)
    AnimationHelpers.modify_on_animation("micro-biolab-1", function (modifier)
      modifier:apply_biolab_modifications()
    end)
    AnimationHelpers.modify_on_animation("micro-alien-lab-1", function (modifier)
      modifier:apply_lab_modifications({
        lab       = "__bobtech__/graphics/entity/lab/lab-alien.png",
        lab_light = "__bobtech__/graphics/entity/lab/lab-alien-light.png",
      })
    end)
  end,
}
