--- Planet Vesta by CPU_BlackHeart
--- https://mods.factorio.com/mod/skewer_planet_vesta

--- @type ModSupport
local mod = {}
if not mods["skewer_planet_vesta"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("gas-manipulation-science-pack", { 1.00, 0.68, 0.87 })
end

return mod
