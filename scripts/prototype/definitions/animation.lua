local consts = require("scripts.shared.consts")

data:extend({
  {
    type = "animation",
    name = consts.LAB_OVERLAY_ANIMATION_NAME,
    filename = consts.GRAPHICS_DIR .. "lab-overlay.png",
    blend_mode = "additive",
    draw_as_glow = true,
    width = 216,
    height = 194,
    frame_count = 33,
    line_length = 11,
    animation_speed = 1 / 3,
    scale = 0.5,
  },
  {
    type = "animation",
    name = consts.BIOLAB_OVERLAY_ANIMATION_NAME,
    filename = consts.GRAPHICS_DIR .. "biolab-overlay.png",
    blend_mode = "additive",
    draw_as_glow = true,
    width = 216,
    height = 194,
    frame_count = 33,
    line_length = 11,
    animation_speed = 1 / 3,
    scale = 0.5,
  },
})
