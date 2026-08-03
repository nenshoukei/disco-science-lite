--- Pyroclast by zoli85
--- https://mods.factorio.com/mod/Pyroclast

--- @type ModSupport
local mod = {}
if not mods["Pyroclast"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("pyroclast-science-pack", { 0.70, 0.15, 0.05 })
end

return mod
