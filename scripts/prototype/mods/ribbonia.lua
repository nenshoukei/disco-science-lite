--- Planet Ribbonia by Powerscooter
--- https://mods.factorio.com/mod/ribbonia

--- @type ModSupport
local mod = {}
if not mods["ribbonia"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("ribbonia-alien-science-pack", { 0.5, 0.32, 0.71 })
end

return mod
