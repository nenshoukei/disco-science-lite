--- 🌐 Planet Muria by AndreusAxolotl
--- https://mods.factorio.com/mod/Muria

--- @type ModSupport
local mod = {}
if not mods["Muria"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("muriatic-science-pack", { 0.69, 1.00, 0.00 })
end

return mod
