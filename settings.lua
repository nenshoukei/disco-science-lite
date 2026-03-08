local consts = require("scripts.shared.consts")

data:extend({
  {
    type = "bool-setting",
    name = consts.FALLBACK_OVERLAY_ENABLED_NAME,
    setting_type = "startup",
    default_value = true,
    order = "su-a[visual]-a",
  },
  {
    type = "int-setting",
    name = consts.COLOR_PATTERN_DURATION_NAME,
    setting_type = "runtime-global",
    default_value = 180,
    minimum_value = 1,
    order = "rg-a[visual]-a",
  },
  {
    type = "int-setting",
    name = consts.COLOR_INTENSITY_NAME,
    setting_type = "runtime-global",
    default_value = 100,
    minimum_value = 1,
    maximum_value = 100,
    order = "rg-a[visual]-b",
  },
  {
    type = "bool-setting",
    name = consts.UNISON_FLICKER_NAME,
    setting_type = "runtime-global",
    default_value = false,
    order = "rg-a[visual]-c",
  },
  {
    type = "int-setting",
    name = consts.LAB_UPDATE_INTERVAL_NAME,
    setting_type = "runtime-global",
    default_value = 6,
    minimum_value = 1,
    order = "rg-b[performance]-a",
  },
})
