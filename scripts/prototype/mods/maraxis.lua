--- Planet Maraxsis by notnotmelon
--- https://mods.factorio.com/mod/maraxsis

if not mods["maraxsis"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("hydraulic-science-pack", { 0.00, 0.55, 0.98 })
  end,
}
