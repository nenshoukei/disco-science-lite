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
    type = "bool-setting",
    name = consts.RANDOM_FLICKER_NAME,
    setting_type = "runtime-global",
    default_value = false,
    order = "a[visual]-b",
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
