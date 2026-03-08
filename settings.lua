local consts = require("scripts.shared.consts")

data:extend({
  {
    type = "int-setting",
    name = consts.COLOR_PATTERN_DURATION_NAME,
    setting_type = "runtime-global",
    default_value = 180,
    minimum_value = 1,
    order = "a[visual]-a",
  },
  {
    type = "int-setting",
    name = consts.COLOR_INTENSITY_NAME,
    setting_type = "runtime-global",
    default_value = 100,
    minimum_value = 1,
    maximum_value = 100,
    order = "a[visual]-b",
  },
  {
    type = "bool-setting",
    name = consts.UNISON_FLICKER_NAME,
    setting_type = "runtime-global",
    default_value = false,
    order = "a[visual]-c",
  },
  {
    type = "int-setting",
    name = consts.LAB_UPDATE_INTERVAL_NAME,
    setting_type = "runtime-global",
    default_value = 6,
    minimum_value = 1,
    order = "b[performance]-a",
  },
})
