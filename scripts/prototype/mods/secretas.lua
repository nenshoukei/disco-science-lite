--- 🌐Secretas&Frozeta by Zach Kolansky
--- https://mods.factorio.com/mod/secretas

--- @type ModSupport
local mod = {}
if not mods["secretas"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("golden-science-pack", { 0.97, 0.75, 0.46 })
end

return mod
