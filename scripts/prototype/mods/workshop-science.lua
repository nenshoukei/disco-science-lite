--- Workshop Science by Frontrider
--- https://mods.factorio.com/mod/workshop-science

--- @type ModSupport
local mod = {}
if not mods["workshop-science"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("workshop-science-pack", { 0.82, 0.58, 0.00 })
end

return mod
