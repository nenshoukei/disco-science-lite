--- SLP - Dyson Sphere Reworked by SLywnow
--- https://mods.factorio.com/mod/slp-dyson-sphere-reworked

if not mods["slp-dyson-sphere-reworked"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("slp-sun-science-pack", { 0.98, 0.92, 0.88 })
  end,
}
