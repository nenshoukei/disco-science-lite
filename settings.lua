data:extend({
  {
    type = "bool-setting",
    name = "mks-dsl-fallback-overlay-enabled" --[[$FALLBACK_OVERLAY_ENABLED_NAME]],
    setting_type = "startup",
    default_value = true,
    order = "su-a[visual]-a",
  },
  {
    type = "int-setting",
    name = "mks-dsl-color-pattern-duration" --[[$COLOR_PATTERN_DURATION_NAME]],
    setting_type = "runtime-global",
    default_value = 180,
    minimum_value = 1,
    order = "rg-a[visual]-b",
  },
  {
    type = "int-setting",
    name = "mks-dsl-color-intensity" --[[$COLOR_INTENSITY_NAME]],
    setting_type = "runtime-global",
    default_value = 100,
    minimum_value = 1,
    maximum_value = 100,
    order = "rg-a[visual]-c",
  },
  {
    type = "int-setting",
    name = "mks-dsl-max-updates-per-tick" --[[$MAX_UPDATES_PER_TICK_NAME]],
    setting_type = "runtime-global",
    default_value = 500,
    minimum_value = 1,
    order = "rg-b[performance]-a",
  },
})
