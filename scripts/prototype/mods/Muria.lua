--- 🌐 Planet Muria by AndreusAxolotl
--- https://mods.factorio.com/mod/Muria

if not mods["Muria"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("muriatic-science-pack", { 0.69, 1.00, 0.00 })
  end,
}
