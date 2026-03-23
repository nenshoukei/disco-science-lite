--- 🌐 Planet Paracelsin by Andreus
--- https://mods.factorio.com/mod/Paracelsin

if not mods["Paracelsin"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("galvanization-science-pack", { 0.71, 0.35, 0.13 })
  end,
}
