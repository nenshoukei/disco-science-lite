--- Tenebris by Big_J
--- https://mods.factorio.com/mod/tenebris
--- Tenebris Prime by MeteorSwarm
--- https://mods.factorio.com/mod/tenebris-prime

--- @type ModSupport
local mod = {}
if not (mods["tenebris"] or mods["tenebris-prime"]) then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("bioluminescent-science-pack", { 0.16, 0.97, 0.95 })
end

return mod
