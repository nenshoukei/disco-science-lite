--- Schall mods by Schallfalke
--- https://mods.factorio.com/user/Schallfalke

if not (mods["SchallAlienLoot"] or mods["SchallMachineScaling"]) then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    if mods["SchallAlienLoot"] then
      PrototypeColorRegistry.set("alien-science-pack", { 0.94, 0.19, 0.65 })
    end

    if mods["SchallMachineScaling"] then
      for i = 1, 6 do
        PrototypeLabRegistry.register("lab-MS-" .. i, {
          scale = i + 1,
          ignores_scale_overrides = true, -- We need to ignore overrides by the mod because it sets wrong scales.
        })
      end
    end
  end,

  on_data_final_fixes = function ()
    for i = 1, 6 do
      AnimationHelpers.modify_on_animation("lab-MS-" .. i, function (modifier)
        modifier:apply_lab_modifications()
      end)
    end
  end,
}
