--- 🌐 Planet Paracelsin by Andreus
--- https://mods.factorio.com/mod/Paracelsin

--- @type ModSupport
local mod = {}
if not mods["Paracelsin"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("galvanization-science-pack", { 0.71, 0.35, 0.13 })
end

return mod
