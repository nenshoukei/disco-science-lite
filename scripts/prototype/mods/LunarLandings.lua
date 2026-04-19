--- Lunar Landings by Xorimuth
--- https://mods.factorio.com/mod/LunarLandings

if not mods["LunarLandings"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["ll-quantum-science-pack"] = { 0.99, 0.18, 0.82 },
      ["ll-space-science-pack"]   = { 0.25, 0.30, 0.93 },
    })
  end,
}
