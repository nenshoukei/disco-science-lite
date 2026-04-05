--- Void Processing by RustyNova016
--- https://mods.factorio.com/mod/VoidProcessing

if not mods["VoidProcessing"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("voidp-void-science-pack", { 0.64, 0.45, 0.95 })
  end,
}
