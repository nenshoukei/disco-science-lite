--- Fusion lab by teemu
--- https://mods.factorio.com/mod/fusion-lab

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

if mods["fusion-lab"] then
  LabPrototypeModifier.set_layer_removal(
    "__fusion-lab__/graphics/entity/fusion-lab/photometric-lab-hr-emission-1.png"
  )
  LabPrototypeModifier.set_layer_mask(
    {
      "__fusion-lab__/graphics/entity/fusion-lab/photometric-lab-hr-animation-1.png",
      "__fusion-lab__/graphics/entity/fusion-lab/photometric-lab-hr-animation-2.png",
    },
    {
      "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "hurricane/photometric-lab-hr-red-light-1.png",
      "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "hurricane/photometric-lab-hr-red-light-2.png",
    },
    {
      blend_mode = "additive",
      draw_as_glow = true,
    }
  )

  data:extend({
    {
      type = "animation",
      name = "mks-dsl-" --[[$NAME_PREFIX]] .. "fusion-lab-overlay",
      filenames = {
        "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "hurricane/photometric-lab-hr-overlay-1.png",
        "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "hurricane/photometric-lab-hr-overlay-2.png",
      },
      lines_per_file = 8,
      line_length = 8,
      frame_count = 80,
      blend_mode = "additive",
      draw_as_glow = true,
      width = 330,
      height = 390,
      shift = util.by_pixel(0, -16),
      scale = 0.5,
      animation_speed = 0.4,
    },
  })

  PrototypeLabRegistry.register("fusion-lab", {
    animation = "mks-dsl-" --[[$NAME_PREFIX]] .. "fusion-lab-overlay",
  })
end
