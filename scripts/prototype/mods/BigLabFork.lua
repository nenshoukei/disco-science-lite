--- Big Lab by DellAquila and _CodeGreen
--- https://mods.factorio.com/mod/BigLabFork

if not mods["BigLabFork"] then return {} end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

return {
  on_data = function ()
    PrototypeLabRegistry.register("big-lab")
  end,
}
