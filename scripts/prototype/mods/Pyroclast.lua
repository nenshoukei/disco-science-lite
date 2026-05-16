--- Pyroclast by zoli85
--- https://mods.factorio.com/mod/Pyroclast

if not mods["Pyroclast"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("pyroclast-science-pack", { 0.70, 0.15, 0.05 })
  end,
}
