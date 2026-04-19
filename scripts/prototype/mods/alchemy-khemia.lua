--- Khemia: Age of Alchemy by GabeWithGlasses
--- https://mods.factorio.com/mod/alchemy-khemia

if not mods["alchemy-khemia"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("alchemical-science", { 0.31, 0.65, 0.23 })
  end,
}
