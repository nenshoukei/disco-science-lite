--- Planet Pelagos by Talandar99
--- https://mods.factorio.com/mod/pelagos

--- @type ModSupport
local mod = {}
if not mods["pelagos"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("pelagos-science-pack", { 0.45, 0.55, 0.31 })
end

return mod
