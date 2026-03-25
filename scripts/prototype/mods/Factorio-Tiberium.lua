--- Factorio and Conquer: Tiberian Dawn by James-Fire
--- https://mods.factorio.com/mod/Factorio-Tiberium

if not mods["Factorio-Tiberium"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("tiberium-science", { r = 0.0, g = 1.0, b = 0.0 })
  end,
}
