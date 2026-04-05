--- Nuclear Science by atanvarno
--- https://mods.factorio.com/mod/atan-nuclear-science

if not mods["atan-nuclear-science"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("nuclear-science-pack", { 0.44, 0.77, 0.22 })
  end,
}
