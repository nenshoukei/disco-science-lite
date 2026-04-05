--- Big Lab by DellAquila and _CodeGreen
--- https://mods.factorio.com/mod/BigLabFork

if not mods["BigLabFork"] then return {} end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeLabRegistry.register("big-lab")
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("big-lab", function (modifier)
      modifier:apply_lab_modifications()
    end)
  end,
}
