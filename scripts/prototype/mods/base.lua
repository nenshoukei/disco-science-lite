--- Factorio base

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

LabPrototypeModifier.set_layer_removal(
  "__base__/graphics/entity/lab/lab-light.png"
)
-- Freeze entity animation at frame 1 (no light, no color in the overlay area).
-- The overlay animation still plays normally to provide the disco color effect.
LabPrototypeModifier.set_animation_freeze(
  "__base__/graphics/entity/lab/lab.png",
  1
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
