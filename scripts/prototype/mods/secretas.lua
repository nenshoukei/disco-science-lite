--- 🌐Secretas&Frozeta by Zach Kolansky
--- https://mods.factorio.com/mod/secretas

if not mods["secretas"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("golden-science-pack", { 0.97, 0.75, 0.46 })
  end,
}
