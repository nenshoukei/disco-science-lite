--- Mod Settings of Disco Science Lite
---
--- @class Settings
--- @field is_fallback_enabled      boolean  Whether the fallback overlay is enabled.
--- @field is_lab_blinking_disabled boolean  Whether the lab blinking is disabled.
--- @field is_development           boolean  Whether Development mode is enabled.
--- @field color_saturation         number   Color saturation. [0, 1]
--- @field color_brightness         number   Color brightness. [0, 1]
--- @field color_pattern_duration   integer  Color function duration in ticks.
--- @field color_update_interval    integer  Color update interval in ticks.
local Settings = {}

function Settings.reload()
  if not settings then return end
  local startup = settings.startup
  local global = settings.global
  if not startup then return end

  Settings.is_fallback_enabled = startup[ "mks-dsl-fallback-overlay-enabled" --[[$FALLBACK_OVERLAY_ENABLED_NAME]] ].value --[[@as boolean]]
  Settings.is_lab_blinking_disabled = startup[ "mks-dsl-lab-blinking-disabled" --[[$LAB_BLINKING_DISABLED_NAME]] ].value --[[@as boolean]]
  Settings.is_development = startup[ "mks-dsl-is-development" --[[$IS_DEVELOPMENT_NAME]] ].value --[[@as boolean]]

  Settings.color_saturation = global and
    (global[ "mks-dsl-color-saturation" --[[$COLOR_SATURATION_NAME]] ].value * 0.01)
    or 1.0
  Settings.color_brightness = global and
    (global[ "mks-dsl-color-brightness" --[[$COLOR_BRIGHTNESS_NAME]] ].value * 0.01)
    or 1.0
  Settings.color_pattern_duration = global and
    global[ "mks-dsl-color-pattern-duration" --[[$COLOR_PATTERN_DURATION_NAME]] ].value --[[@as number]]
    or 180 --[[$DEFAULT_COLOR_PATTERN_DURATION]]
  Settings.color_update_interval = global and
    global[ "mks-dsl-color-update-interval" --[[$COLOR_UPDATE_INTERVAL_NAME]] ].value --[[@as number]]
    or 1
end

Settings.reload()

return Settings
