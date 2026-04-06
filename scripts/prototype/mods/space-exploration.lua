--- Space Exploration by Earendel
--- https://mods.factorio.com/mod/space-exploration

if not mods["space-exploration"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["production-science-pack"]      = { 1.00, 0.00, 0.00 },
      ["utility-science-pack"]         = { 0.00, 1.00, 0.80 },

      ["se-rocket-science-pack"]       = { 1.00, 0.53, 0.16 },
      ["se-astronomic-science-pack-1"] = { 0.00, 0.20, 0.93 },
      ["se-astronomic-science-pack-2"] = { 0.00, 0.20, 0.93 },
      ["se-astronomic-science-pack-3"] = { 0.00, 0.20, 0.93 },
      ["se-astronomic-science-pack-4"] = { 0.00, 0.20, 0.93 },
      ["se-biological-science-pack-1"] = { 0.42, 0.93, 0.16 },
      ["se-biological-science-pack-2"] = { 0.42, 0.93, 0.16 },
      ["se-biological-science-pack-3"] = { 0.42, 0.93, 0.16 },
      ["se-biological-science-pack-4"] = { 0.42, 0.93, 0.16 },
      ["se-energy-science-pack-1"]     = { 1.00, 0.17, 0.91 },
      ["se-energy-science-pack-2"]     = { 1.00, 0.17, 0.91 },
      ["se-energy-science-pack-3"]     = { 1.00, 0.17, 0.91 },
      ["se-energy-science-pack-4"]     = { 1.00, 0.17, 0.91 },
      ["se-material-science-pack-1"]   = { 1.00, 0.53, 0.12 },
      ["se-material-science-pack-2"]   = { 1.00, 0.53, 0.12 },
      ["se-material-science-pack-3"]   = { 1.00, 0.53, 0.12 },
      ["se-material-science-pack-4"]   = { 1.00, 0.53, 0.12 },
      ["se-deep-space-science-pack-1"] = { 0.28, 0.00, 0.84 },
      ["se-deep-space-science-pack-2"] = { 0.28, 0.00, 0.84 },
      ["se-deep-space-science-pack-3"] = { 0.28, 0.00, 0.84 },
      ["se-deep-space-science-pack-4"] = { 0.28, 0.00, 0.84 },
    })

    if mods["Krastorio2"] then
      PrototypeColorRegistry.set_by_table({
        ["kr-matter-research-data"]     = { 1.00, 0.20, 0.60 },
        ["kr-matter-tech-card"]         = { 1.00, 0.20, 0.60 },
        ["se-kr-matter-science-pack-2"] = { 1.00, 0.20, 0.60 },
        ["kr-advanced-tech-card"]       = { 0.52, 0.13, 0.82 },
        ["kr-singularity-tech-card"]    = { 0.52, 0.13, 0.82 },
        ["kr-optimization-tech-card"]   = { 1.00, 0.50, 0.00 },
      })
    end

    -- We cannot colorize the space science lab because it needs a grayscale mask, but
    -- it is not allowed to make any deriviations by the mod's license.
    PrototypeLabRegistry.exclude("se-space-science-lab")
  end,
}
