--- Factorio Space-Age DLC

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

if mods["space-age"] then
  local animation = "mks-dsl-" --[[$NAME_PREFIX]] .. "biolab-overlay"

  LabPrototypeModifier.set_filename_replacement(
    "__space-age__/graphics/entity/biolab/biolab-anim.png",
    "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "factorio/biolab-masked.png"
  )
  LabPrototypeModifier.set_filename_removal(
    "__space-age__/graphics/entity/biolab/biolab-lights.png"
  )

  data:extend({
    {
      type = "animation",
      name = animation,
      filename = "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "factorio/biolab-overlay.png",
      blend_mode = "additive",
      draw_as_glow = true,
      width = 326,
      height = 362,
      frame_count = 32,
      line_length = 8,
      animation_speed = 0.2,
      scale = 0.5,
      shift = { 1.0 / 32, -6.5 / 32 },
    },
  })

  PrototypeLabRegistry.register("biolab", {
    animation = animation,
  })
end
