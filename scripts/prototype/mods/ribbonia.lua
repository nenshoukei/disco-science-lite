--- Planet Ribbonia by Powerscooter
--- https://mods.factorio.com/mod/ribbonia

if not mods["ribbonia"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("ribbonia-alien-science-pack", { 0.5, 0.32, 0.71 })
  end,
}
