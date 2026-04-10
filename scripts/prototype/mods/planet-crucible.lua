--- Planet Crucible by thremtopod
--- https://mods.factorio.com/mod/planet-crucible

if not mods["planet-crucible"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("planet-crucible-science-pack", { 0.54, 0.18, 0.26 })
  end,
}
