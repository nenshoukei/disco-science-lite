--- Planet Omnia by Wwombatt
--- https://mods.factorio.com/mod/omnia

if not mods["omnia"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("omnia-basic-science-pack", { 0.82, 0.37, 0.83 })
  end,
}
