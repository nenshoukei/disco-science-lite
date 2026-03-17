--- Krastorio2 by raiguard
--- https://mods.factorio.com/mod/Krastorio2

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

if mods["Krastorio2"] then
  LabPrototypeModifier.set_layer_removal(
    "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-light-anim.png",
    "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-glow-light.png",
    "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-glow.png"
  )
  LabPrototypeModifier.set_layer_mask(
    "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-anim.png",
    "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "laborat/lab_albedo_anim-mask.png"
  )
  LabPrototypeModifier.set_layer_mask(
    "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-working.png",
    "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "Krastorio2/singularity-lab-mask.png"
  )

  data:extend({
    {
      type = "animation",
      name = "mks-dsl-" --[[$NAME_PREFIX]] .. "kr-advanced-lab-overlay",
      filename = "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "laborat/lab_albedo_anim-overlay.png",
      blend_mode = "additive",
      draw_as_glow = true,
      width = 150,
      height = 150,
      frame_count = 1,
      shift = { 0, -0.05 },
      scale = 0.64,
    },
    {
      type = "animation",
      name = "mks-dsl-" --[[$NAME_PREFIX]] .. "kr-singularity-lab-overlay",
      filename = "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "Krastorio2/singularity-lab-overlay.png",
      blend_mode = "additive",
      draw_as_glow = true,
      width = 520,
      height = 500,
      frame_count = 1,
      shift = { 0, -0.1 },
      scale = 0.5,
    },
  })

  PrototypeLabRegistry.register("kr-advanced-lab", {
    animation = "mks-dsl-" --[[$NAME_PREFIX]] .. "kr-advanced-lab-overlay",
  })
  PrototypeLabRegistry.register("kr-singularity-lab", {
    animation = "mks-dsl-" --[[$NAME_PREFIX]] .. "kr-singularity-lab-overlay",
  })
end
