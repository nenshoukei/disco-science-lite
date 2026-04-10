--- Shchierbin by Magistr-Djo
--- https://mods.factorio.com/mod/shchierbin

if not mods["shchierbin"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("vanadium-science-pack", { 0.53, 0.33, 0.48 })
  end,
}
