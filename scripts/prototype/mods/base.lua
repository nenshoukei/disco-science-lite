--- Factorio base

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

LabPrototypeModifier.set_filename_replacement(
  "__base__/graphics/entity/lab/lab.png",
  "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "factorio/lab-masked.png"
)
LabPrototypeModifier.set_filename_removal(
  "__base__/graphics/entity/lab/lab-light.png"
)

if settings.startup[ "mks-dsl-disable-lab-blinking" --[[$DISABLE_LAB_BLINKING_NAME]] ].value then
  -- Freeze lab overlay animation at frame index 2
  local overlay = data.raw["animation"][ "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]] ]
  if overlay then
    overlay.frame_sequence = { 2 }
  end
end

PrototypeLabRegistry.register("lab", {
  animation = "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]],
})
