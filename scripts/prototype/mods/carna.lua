--- Carna by amHunter
--- https://mods.factorio.com/mod/carna

if not mods["carna"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("carnal-science-pack", { 0.20, 0.81, 0.69 })
  end,
}
