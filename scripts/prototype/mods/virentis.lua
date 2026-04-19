--- Planet Virentis by SoulCRYSIS
--- https://mods.factorio.com/mod/virentis

if not mods["virentis"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeColorRegistry.set("mudland-research-data", { 0.95, 0.87, 0.65 })

    PrototypeLabRegistry.register("virentis-biolab", {
      animation = "mks-dsl-biolab-overlay" --[[$NAME_PREFIX .. "biolab-overlay"]],
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("virentis-biolab", function (modifier)
      modifier:apply_biolab_modifications()
    end)
  end,
}
