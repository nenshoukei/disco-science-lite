--- Outer Rim by Frontrider
--- https://mods.factorio.com/mod/outer-rim

if not mods["outer-rim"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["outer-rim-thermodynamic-science-pack"] = { 0.38, 0.87, 1.00 },
      ["outer-rim-cryochemical-science-pack"]  = { 0.56, 0.64, 0.91 },
      ["outer-rim-insulation-science-pack"]    = { 0.37, 0.95, 0.35 },
      ["outer-rim-spacecraft-science-pack"]    = { 0.56, 0.42, 1.00 },
    })
  end,
}
