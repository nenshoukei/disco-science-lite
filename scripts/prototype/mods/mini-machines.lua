--- Mini Machines Mod by Kryzeth
--- https://mods.factorio.com/mod/mini-machines

if not mods["mini-machines"] then return {} end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeLabRegistry.register("mini-lab-1", {
      scale = 2 / 3,
    })
    PrototypeLabRegistry.register("mini-biolab-1", {
      animation = "mks-dsl-biolab-overlay" --[[$NAME_PREFIX .. "biolab-overlay"]],
      scale = 3 / 5,
    })
    PrototypeLabRegistry.register("mini-alien-lab-1", {
      scale = 2 / 3,
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("mini-lab-1", function (modifier)
      modifier:apply_lab_modifications()
    end)
    AnimationHelpers.modify_on_animation("mini-biolab-1", function (modifier)
      modifier:apply_biolab_modifications()
    end)
    AnimationHelpers.modify_on_animation("mini-alien-lab-1", function (modifier)
      modifier:apply_lab_modifications({
        lab       = "__bobtech__/graphics/entity/lab/lab-alien.png",
        lab_light = "__bobtech__/graphics/entity/lab/lab-alien-light.png",
      })
    end)
  end,
}
