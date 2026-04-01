--- Rabbasca, the forgotten Moon by PizzaPlanner
--- https://mods.factorio.com/mod/planet-rabbasca

if not mods["planet-rabbasca"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("athletic-science-pack", { 0.24, 0.76, 0.35 })
  end,
}
