--- Factorio base

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

PrototypeColorRegistry.set_by_table({
  ["automation-science-pack"]      = { 0.91, 0.16, 0.20 },
  ["logistic-science-pack"]        = { 0.29, 0.97, 0.31 },
  ["chemical-science-pack"]        = { 0.28, 0.93, 0.95 },
  ["production-science-pack"]      = { 0.83, 0.06, 0.92 },
  ["military-science-pack"]        = { 0.50, 0.10, 0.50 },
  ["utility-science-pack"]         = { 0.96, 0.93, 0.30 },
  ["space-science-pack"]           = { 0.80, 0.80, 0.80 },
  ["agricultural-science-pack"]    = { 0.84, 0.84, 0.15 },
  ["metallurgic-science-pack"]     = { 0.99, 0.50, 0.04 },
  ["electromagnetic-science-pack"] = { 0.89, 0.00, 0.56 },
  ["cryogenic-science-pack"]       = { 0.14, 0.18, 0.74 },
  ["promethium-science-pack"]      = { 0.10, 0.10, 0.50 },
})

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
