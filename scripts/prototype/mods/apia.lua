--- Apia-Carnova planet system by DimonSever000
--- https://mods.factorio.com/mod/apia

if not mods["apia"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("apicultural-science-pack", {
      { 0.96, 0.93, 0.30 },
      { 0.91, 0.16, 0.20 },
    })
  end,
}
