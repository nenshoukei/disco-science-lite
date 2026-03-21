--- 🌐Corrundum by AnotherZach
--- https://mods.factorio.com/mod/corrundum

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

if mods["corrundum"] then
  PrototypeColorRegistry.set("electrochemical-science-pack", { 0.91, 0.71, 0.27 })

  LabPrototypeModifier.set_animation_freeze(
    "__corrundum__/graphics/entity/lab-3-x-frame.png",
    1
  )
  LabPrototypeModifier.set_layer_removal(
    "__corrundum__/graphics/entity/chemical-plant-smoke-outer-blue.png",
    "__corrundum__/graphics/entity/chemical-plant-smoke-inner-blue.png",
    "__corrundum__/graphics/entity/lab-light-three-times-frames-no-change.png"
  )

  --- frame_count for all layers of the overlay
  local FRAME_COUNT = 47

  local lab_overlay = data.raw["animation"][ "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]] ]
  local lab_frame_sequence = lab_overlay.frame_sequence
  if not lab_frame_sequence then
    -- Make a full frame_sequence for the lab overlay
    lab_frame_sequence = {}
    for i = 1, lab_overlay.frame_count do
      lab_frame_sequence[i] = i
    end
  end

  -- Repeat the lab overlay's frame_sequence until it fits to FRAME_COUNT.
  local repeated_frame_sequence = {}
  local n_lab_frame_sequence = #lab_frame_sequence
  local index = 1
  for i = 1, FRAME_COUNT do
    repeated_frame_sequence[i] = lab_frame_sequence[index]
    index = index == n_lab_frame_sequence and 1 or (index + 1)
  end

  data:extend({
    {
      type = "animation",
      name = "mks-dsl-" --[[$NAME_PREFIX]] .. "pressure-lab-overlay",
      layers = {
        {
          filename = lab_overlay.filename,
          blend_mode = "additive",
          draw_as_glow = true,
          width = lab_overlay.width,
          height = lab_overlay.height,
          line_length = lab_overlay.line_length,
          animation_speed = lab_overlay.animation_speed,
          scale = lab_overlay.scale,
          frame_sequence = repeated_frame_sequence,
          frame_count = FRAME_COUNT,
        },
        {
          filename = "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "corrundum/chemical-plant-smoke-outer-grayscaled.png",
          frame_count = FRAME_COUNT,
          line_length = 16,
          width = 90,
          height = 188,
          animation_speed = 0.5,
          scale = 0.5,
          shift = util.by_pixel_hr(-30, -228),
        },
        {
          filename = "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "corrundum/chemical-plant-smoke-inner-grayscaled.png",
          frame_count = FRAME_COUNT,
          line_length = 16,
          width = 40,
          height = 84,
          animation_speed = 0.5,
          scale = 0.5,
          shift = util.by_pixel_hr(-30, -228),
        },
      },
    },
    {
      type = "animation",
      name = "mks-dsl-" --[[$NAME_PREFIX]] .. "pressure-lab-companion",
      filename = "__corrundum__/graphics/entity/chem-lab-on-mask.png",
      width = 220,
      height = 292,
      scale = 0.5,
      shift = util.by_pixel(0.5, -9),
    },
  })

  PrototypeLabRegistry.register("pressure-lab", {
    animation = "mks-dsl-" --[[$NAME_PREFIX]] .. "pressure-lab-overlay",
    companion = "mks-dsl-" --[[$NAME_PREFIX]] .. "pressure-lab-companion",
  })
end
