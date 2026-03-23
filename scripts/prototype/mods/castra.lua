--- Planet Castra by Bartz24
--- https://mods.factorio.com/mod/castra

if not mods["castra"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("battlefield-science-pack", { 0.46, 0.07, 0.07 })
  end,
}
