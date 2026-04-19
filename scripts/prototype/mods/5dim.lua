--- 5Dim's mod - New Automatization by McGuten
--- https://mods.factorio.com/mod/5dim_automation

if not mods["5dim_automation"] then return {} end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

local LAB_NUMBERS = { "02", "03", "04", "05", "06", "07", "08", "09", "10" }

return {
  on_data = function ()
    for _, n in ipairs(LAB_NUMBERS) do
      PrototypeLabRegistry.register("5d-lab-" .. n) -- uses the vanilla lab overlay
    end
  end,

  on_data_final_fixes = function ()
    for _, n in ipairs(LAB_NUMBERS) do
      AnimationHelpers.modify_on_animation("5d-lab-" .. n, function (modifier)
        modifier:apply_lab_modifications({
          lab = "__5dim_automation__/graphics/entities/lab/lab-" .. n .. ".png",
        })
      end)
    end
  end,
}
