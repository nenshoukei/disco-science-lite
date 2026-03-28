--- Mod Settings of Disco Science Lite
---
--- @class Settings
--- @field is_fallback_enabled         boolean  Whether the fallback overlay is enabled.
--- @field is_lab_blinking_disabled    boolean  Whether the lab blinking is disabled.
--- @field is_development              boolean  Whether Development mode is enabled.
--- @field color_saturation            number   Color saturation. [0, 1]
--- @field color_brightness            number   Color brightness. [0, 1]
--- @field color_pattern_duration      integer  Color function duration in ticks.
--- @field color_update_preset         string   Color update preset name. One of "smooth", "balanced", "performance".
--- @field color_update_budget         integer  Max color updates per game tick, derived from color_update_preset.
--- @field color_update_max_per_call   integer  Max overlay updates per single tick function call, derived from color_update_preset.
local Settings = {}

--- @type table<string, integer>
local BUDGET_BY_PRESET = {
  smooth = 500,
  balanced = 200,
  performance = 50,
}

--- @type table<string, integer>
local MAX_PER_CALL_BY_PRESET = {
  smooth = 1000,
  balanced = 500,
  performance = 100,
}

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
  Settings.color_update_preset = global and
    global[ "mks-dsl-color-update-preset" --[[$COLOR_UPDATE_PRESET_NAME]] ].value --[[@as string]]
    or "balanced"
  Settings.color_update_budget = BUDGET_BY_PRESET[Settings.color_update_preset] or BUDGET_BY_PRESET.balanced
  Settings.color_update_max_per_call = MAX_PER_CALL_BY_PRESET[Settings.color_update_preset] or MAX_PER_CALL_BY_PRESET.balanced
end

Settings.reload()

return Settings
