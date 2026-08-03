--- Nuclear Science by atanvarno
--- https://mods.factorio.com/mod/atan-nuclear-science

--- @type ModSupport
local mod = {}
if not mods["atan-nuclear-science"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("nuclear-science-pack", { 0.44, 0.77, 0.22 })
end

return mod
