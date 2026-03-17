--- Factorio Space-Age DLC

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

if mods["space-age"] then
  LabPrototypeModifier.set_layer_removal(
    "__space-age__/graphics/entity/biolab/biolab-lights.png"
  )

  data:extend({
    {
      type = "animation",
      name = "mks-dsl-" --[[$NAME_PREFIX]] .. "biolab-overlay",
      filename = "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "factorio/biolab-overlay.png",
      blend_mode = "additive",
      draw_as_glow = true,
      width = 326,
      height = 362,
      frame_count = 32,
      line_length = 8,
      animation_speed = 0.2,
      scale = 0.5,
      shift = { 1.0 / 32 --[[$TILE_SIZE]], -6.5 / 32 --[[$TILE_SIZE]] },
    },
  })

  PrototypeLabRegistry.add_overlay_detection(
    "mks-dsl-" --[[$NAME_PREFIX]] .. "biolab-overlay",
    { "__space-age__/graphics/entity/biolab/biolab.png" }
  )

  PrototypeLabRegistry.register("biolab", {
    animation = "mks-dsl-" --[[$NAME_PREFIX]] .. "biolab-overlay",
  })
end
