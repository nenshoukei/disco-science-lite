--- Khemia: Age of Alchemy by GabeWithGlasses
--- https://mods.factorio.com/mod/alchemy-khemia

--- @type ModSupport
local mod = {}
if not mods["alchemy-khemia"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("alchemical-science", { 0.31, 0.65, 0.23 })
end

return mod
