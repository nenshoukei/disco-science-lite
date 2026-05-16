--- Arboria by nicvampire
--- https://mods.factorio.com/mod/arboria

if not mods["arboria"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("arboric-science-pack", { 0.47, 0.06, 0.14 })
  end,
}
