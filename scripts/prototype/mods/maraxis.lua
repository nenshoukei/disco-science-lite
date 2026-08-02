--- Planet Maraxsis by notnotmelon
--- https://mods.factorio.com/mod/maraxsis

--- @type ModSupport
local mod = {}
if not mods["maraxsis"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("hydraulic-science-pack", { 0.00, 0.55, 0.98 })
end

return mod
