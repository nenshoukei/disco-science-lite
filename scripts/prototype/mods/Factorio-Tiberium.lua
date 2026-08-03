--- Factorio and Conquer: Tiberian Dawn by James-Fire
--- https://mods.factorio.com/mod/Factorio-Tiberium

--- @type ModSupport
local mod = {}
if not mods["Factorio-Tiberium"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("tiberium-science", { 0.0, 1.0, 0.0 })
end

return mod
