--- 5Dim's mod - New Automatization by McGuten
--- https://mods.factorio.com/mod/5dim_automation

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

if mods["5dim_automation"] then
  for _, n in ipairs({ "02", "03", "04", "05", "06", "07", "08", "09", "10" }) do
    -- Revert the colorized version on_animation to the default vanilla lab (gray), which is frozen at frame 1.
    LabPrototypeModifier.set_filename_replacement(
      "__5dim_automation__/graphics/entities/lab/lab-" .. n .. ".png",
      "__base__/graphics/entity/lab/lab.png"
    )

    PrototypeLabRegistry.register("5d-lab-" .. n)
  end
end
