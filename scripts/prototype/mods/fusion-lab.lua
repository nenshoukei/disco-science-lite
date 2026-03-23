--- Fusion lab by teemu
--- https://mods.factorio.com/mod/fusion-lab

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local table_merge = require("scripts.shared.utils").table_merge

if mods["fusion-lab"] then
  LabPrototypeModifier.set_layer_removal(
    "__fusion-lab__/graphics/entity/fusion-lab/photometric-lab-hr-emission-1.png"
  )

  local shared_props = {
    lines_per_file = 8,
    line_length = 8,
    frame_count = 80,
    width = 330,
    height = 390,
    shift = util.by_pixel(0, -16),
    scale = 0.5,
    animation_speed = 0.4,
  }

  data:extend({
    table_merge(shared_props, {
      type = "animation",
      name = "mks-dsl-fusion-lab-overlay" --[[$NAME_PREFIX .. "fusion-lab-overlay"]],
      filenames = {
        "__disco-science-lite__/graphics/hurricane/photometric-lab-hr-overlay-1.png" --[[$GRAPHICS_DIR .. "hurricane/photometric-lab-hr-overlay-1.png"]],
        "__disco-science-lite__/graphics/hurricane/photometric-lab-hr-overlay-2.png" --[[$GRAPHICS_DIR .. "hurricane/photometric-lab-hr-overlay-2.png"]],
      },
      blend_mode = "additive",
      draw_as_glow = true,
    }),

    -- Companion to make the animation sync-ed with the overlay by overriding moving parts.
    table_merge(shared_props, {
      type = "animation",
      name = "mks-dsl-fusion-lab-companion" --[[$NAME_PREFIX .. "fusion-lab-companion"]],
      filenames = {
        "__disco-science-lite__/graphics/hurricane/photometric-lab-hr-override-1.png" --[[$GRAPHICS_DIR .. "hurricane/photometric-lab-hr-override-1.png"]],
        "__disco-science-lite__/graphics/hurricane/photometric-lab-hr-override-2.png" --[[$GRAPHICS_DIR .. "hurricane/photometric-lab-hr-override-2.png"]],
      },
    }),
  })

  PrototypeLabRegistry.register("fusion-lab", {
    animation = "mks-dsl-fusion-lab-overlay" --[[$NAME_PREFIX .. "fusion-lab-overlay"]],
    companion = "mks-dsl-fusion-lab-companion" --[[$NAME_PREFIX .. "fusion-lab-companion"]],
    is_companion_under_overlay = true,
  })
end
