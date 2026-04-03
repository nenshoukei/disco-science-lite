--- Nexus Extended Promethium Endgame by Karu_Kiruna
--- https://mods.factorio.com/mod/Nexus

if not mods["Nexus"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["promethium-882-science-pack"]        = { 0.31, 0.38, 0.49 },
      ["antimatter-science-pack"]            = { 0.29, 0.29, 0.63 },
      ["omega-automation-science-pack"]      = { 0.93, 0.22, 0.23 },
      ["omega-logistic-science-pack"]        = { 0.27, 0.92, 0.37 },
      ["omega-military-science-pack"]        = { 0.56, 0.60, 0.68 },
      ["omega-chemical-science-pack"]        = { 0.22, 0.92, 0.95 },
      ["omega-production-science-pack"]      = { 0.86, 0.27, 0.92 },
      ["omega-utility-science-pack"]         = { 0.98, 0.89, 0.36 },
      ["omega-space-science-pack"]           = { 0.98, 0.98, 0.98 },
      ["omega-metallurgic-science-pack"]     = { 1.00, 0.64, 0.19 },
      ["omega-agricultural-science-pack"]    = { 0.76, 0.75, 0.15 },
      ["omega-electromagnetic-science-pack"] = { 0.97, 0.28, 0.70 },
      ["omega-cryogenic-science-pack"]       = { 0.12, 0.35, 0.80 },
    })

    PrototypeLabRegistry.exclude("omega-lab")
  end,
}
