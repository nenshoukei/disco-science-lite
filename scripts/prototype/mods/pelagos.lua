--- Planet Pelagos by Talandar99
--- https://mods.factorio.com/mod/pelagos

if not mods["pelagos"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("pelagos-science-pack", { 0.45, 0.55, 0.31 })
  end,
}
