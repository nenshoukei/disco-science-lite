--- Void Processing by RustyNova016
--- https://mods.factorio.com/mod/VoidProcessing

--- @type ModSupport
local mod = {}
if not mods["VoidProcessing"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("voidp-void-science-pack", { 0.64, 0.45, 0.95 })
end

return mod
