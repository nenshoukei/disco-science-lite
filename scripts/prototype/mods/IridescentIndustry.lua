--- Iridescent Industry by S6X
--- https://mods.factorio.com/mod/IridescentIndustry

--- @type ModSupport
local mod = {}
if not mods["IridescentIndustry"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set_by_table({
    ["iridescent-science-pack"]    = { 0.04, 0.99, 0.77 },
    ["polychromatic-science-pack"] = { 1.00, 0.97, 0.48 },
  })
end

return mod
