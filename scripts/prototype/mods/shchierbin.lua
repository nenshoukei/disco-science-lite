--- Shchierbin by Magistr-Djo
--- https://mods.factorio.com/mod/shchierbin

--- @type ModSupport
local mod = {}
if not mods["shchierbin"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("vanadium-science-pack", { 0.53, 0.33, 0.48 })
end

return mod
