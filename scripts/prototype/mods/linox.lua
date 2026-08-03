--- Planet Linox by Xeon257
--- https://mods.factorio.com/mod/linox

--- @type ModSupport
local mod = {}
if not mods["linox"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("linox-item_dysprosium-data-card", { 0.55, 0.25, 0.12 })

  -- We cannot colorize it because it uses assets from space-exploration, which does not allow any deriviations.
  PrototypeLabRegistry.exclude("linox-building_linox-supercomputer")
end

return mod
