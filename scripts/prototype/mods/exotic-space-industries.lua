--- Exotic Space Industries by eliont and PreLeyZero
--- https://mods.factorio.com/mod/exotic-space-industries
--- Exotic Space Industries: Remembrance by aRighteousGod
--- https://mods.factorio.com/mod/exotic-space-industries-remembrance

if not (mods["exotic-space-industries"] or mods["exotic-space-industries-remembrance"]) then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["ei-dark-age-tech"]              = { 1.00, 0.02, 0.08 },
      ["ei-steam-age-tech"]             = { 0.00, 0.86, 0.15 },
      ["ei-electricity-age-tech"]       = { 0.00, 0.97, 1.00 },
      ["ei-computer-age-tech"]          = { 0.98, 0.89, 0.17 },
      ["ei-advanced-computer-age-tech"] = { 0.00, 0.99, 0.60 },
      ["ei-alien-computer-age-tech"]    = { 1.00, 0.57, 0.56 },
      ["ei-quantum-age-tech"]           = { 1.00, 0.29, 0.98 },
      ["ei-fusion-quantum-age-tech"]    = { 1.00, 0.70, 0.47 },
      ["ei-exotic-age-tech"]            = { 0.78, 0.97, 0.17 },
      ["ei-black-hole-exotic-age-tech"] = { 1.00, 0.68, 0.37 },

      ["space-science-pack"]            = { 0.84, 0.75, 0.21 },
    })

    PrototypeLabRegistry.register("ei-dark-age-lab") -- uses the vanilla lab overlay

    -- We cannot make an overlay for the ei-big-lab (Advanced lab) because it requires GPLv3 license.
    -- Its animation already has color changing effect, so it does not matter so much.
    PrototypeLabRegistry.exclude("ei-big-lab")
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("ei-dark-age-lab", function (modifier)
      modifier:apply_lab_modifications()
    end)
  end,
}
