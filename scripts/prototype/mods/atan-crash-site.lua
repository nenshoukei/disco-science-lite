--- Crash Site by atanvarno
--- https://mods.factorio.com/mod/atan-crash-site

if not mods["atan-crash-site"] then return {} end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

return {
  on_data = function ()
    PrototypeLabRegistry.exclude("crash-site-lab")
  end,
}
