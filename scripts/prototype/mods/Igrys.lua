--- 🌐Igrys by Egorex W
--- https://mods.factorio.com/mod/Igrys

--- @type ModSupport
local mod = {}
if not mods["Igrys"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("igrys-mineral-science-pack", { 0.3, 0.52, 0.34 })
end

return mod
