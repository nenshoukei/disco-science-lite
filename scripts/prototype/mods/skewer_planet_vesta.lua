--- Planet Vesta by CPU_BlackHeart
--- https://mods.factorio.com/mod/skewer_planet_vesta

if not mods["skewer_planet_vesta"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("gas-manipulation-science-pack", { 1.00, 0.68, 0.87 })
  end,
}
