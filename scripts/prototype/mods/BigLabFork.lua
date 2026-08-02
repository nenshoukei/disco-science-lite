--- Big Lab by DellAquila and _CodeGreen
--- https://mods.factorio.com/mod/BigLabFork

--- @type ModSupport
local mod = {}
if not mods["BigLabFork"] then return mod end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

mod.on_data = function ()
  PrototypeLabRegistry.register("big-lab")
end

mod.on_data_final_fixes = function ()
  AnimationHelpers.modify_on_animation("big-lab", function (modifier)
    modifier:apply_lab_modifications()
  end)
end

return mod
