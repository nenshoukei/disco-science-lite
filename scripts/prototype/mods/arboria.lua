--- Arboria by nicvampire
--- https://mods.factorio.com/mod/arboria

--- @type ModSupport
local mod = {}
if not mods["arboria"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("arboric-science-pack", { 0.47, 0.06, 0.14 })
end

return mod
