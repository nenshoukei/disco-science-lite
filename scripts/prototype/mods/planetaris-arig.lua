--- 🌐Planetaris: Arig by Syen
--- https://mods.factorio.com/mod/planetaris-arig

if not mods["planetaris-arig"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("planetaris-compression-science-pack", { 0.918, 0.773, 0.671 })
  end,
}
