--- 🌐Igrys by Egorex W
--- https://mods.factorio.com/mod/Igrys

if not mods["Igrys"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("igrys-mineral-science-pack", { 0.3, 0.52, 0.34 })
  end,
}
