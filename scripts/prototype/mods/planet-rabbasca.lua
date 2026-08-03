--- Rabbasca, the forgotten Moon by PizzaPlanner
--- https://mods.factorio.com/mod/planet-rabbasca

--- @type ModSupport
local mod = {}
if not mods["planet-rabbasca"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("athletic-science-pack", { 0.24, 0.76, 0.35 })

  PrototypeLabRegistry.add_prefix("harene-infused-")
end

return mod
