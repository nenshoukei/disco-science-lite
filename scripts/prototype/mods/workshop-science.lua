--- Workshop Science by Frontrider
--- https://mods.factorio.com/mod/workshop-science

if not mods["workshop-science"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("workshop-science-pack", { 0.82, 0.58, 0.00 })
  end,
}
