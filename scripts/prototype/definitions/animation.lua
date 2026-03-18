local is_blinking_disabled = settings.startup[ "mks-dsl-disable-lab-blinking" --[[$DISABLE_LAB_BLINKING_NAME]] ].value

data:extend({
  {
    type = "animation",
    name = "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]],
    filename = "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "factorio/lab-overlay.png",
    blend_mode = "additive",
    draw_as_glow = true,
    width = 216,
    height = 194,
    frame_count = 33,
    line_length = 11,
    animation_speed = 1 / 3,
    scale = 0.5,
    frame_sequence = is_blinking_disabled and { 2, 9, 12, 13, 26, 27 } or nil, -- Skips blinking frames
  },
  {
    type = "animation",
    name = "mks-dsl-general-overlay" --[[$GENERAL_OVERLAY_ANIMATION_NAME]],
    filename = "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "general-overlay.png",
    blend_mode = "additive",
    draw_as_glow = true,
    width = 128,
    height = 128,
    frame_count = 1,
    scale = 0.5,
  },
})
