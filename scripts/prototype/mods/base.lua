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

PrototypeLabRegistry.register("lab", {
  animation = "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]],
})
