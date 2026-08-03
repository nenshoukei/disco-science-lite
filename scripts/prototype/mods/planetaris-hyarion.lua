--- Planetaris: Hyarion by Syen
--- https://mods.factorio.com/mod/planetaris-hyarion

--- @type ModSupport
local mod = {}
if not mods["planetaris-hyarion"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set_by_table({
    ["planetaris-polishing-science-pack"] = { 0.80, 0.79, 0.97 },
    ["planetaris-refraction-science-pack"] = { 0.79, 0.84, 0.85 },
  })
end

return mod
