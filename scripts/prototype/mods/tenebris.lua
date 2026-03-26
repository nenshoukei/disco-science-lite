--- Tenebris by Big_J
--- https://mods.factorio.com/mod/tenebris
--- Tenebris Prime by MeteorSwarm
--- https://mods.factorio.com/mod/tenebris-prime

if not (mods["tenebris"] or mods["tenebris-prime"]) then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("bioluminescent-science-pack", { 0.16, 0.97, 0.95 })
  end,
}
