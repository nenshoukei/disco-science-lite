--- Carna by amHunter
--- https://mods.factorio.com/mod/carna

--- @type ModSupport
local mod = {}
if not mods["carna"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("carnal-science-pack", { 0.20, 0.81, 0.69 })
end

return mod
