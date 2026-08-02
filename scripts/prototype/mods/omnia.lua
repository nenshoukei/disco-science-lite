--- Planet Omnia by Wwombatt
--- https://mods.factorio.com/mod/omnia

--- @type ModSupport
local mod = {}
if not mods["omnia"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("omnia-basic-science-pack", { 0.82, 0.37, 0.83 })
end

return mod
