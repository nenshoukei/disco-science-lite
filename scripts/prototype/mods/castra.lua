--- Planet Castra by Bartz24
--- https://mods.factorio.com/mod/castra

--- @type ModSupport
local mod = {}
if not mods["castra"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("battlefield-science-pack", { 0.46, 0.07, 0.07 })
end

return mod
