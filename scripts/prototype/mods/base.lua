--- Factorio base

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

PrototypeColorRegistry.set_by_table({
  ["automation-science-pack"] = { 0.91, 0.16, 0.20 },
  ["logistic-science-pack"]   = { 0.29, 0.97, 0.31 },
  ["chemical-science-pack"]   = { 0.28, 0.93, 0.95 },
  ["production-science-pack"] = { 0.83, 0.06, 0.92 },
  ["military-science-pack"]   = { 0.58, 0.61, 0.68 },
  ["utility-science-pack"]    = { 0.96, 0.93, 0.30 },
  ["space-science-pack"]      = { 1.00, 1.00, 1.00 },
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

PrototypeLabRegistry.add_overlay_detection(
  "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]],
  { "__base__/graphics/entity/lab/lab.png" }
)

PrototypeLabRegistry.register("lab", {
  animation = "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]],
})
