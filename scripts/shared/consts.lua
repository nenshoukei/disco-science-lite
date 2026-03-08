local PREFIX = "mks-dsl"
local NAME_PREFIX = PREFIX .. "-"
local MOD_NAME = "disco-science-lite"
local MOD_DIR = "__" .. MOD_NAME .. "__/"
local GRAPHICS_DIR = MOD_DIR .. "graphics/"

local consts = {
  PREFIX = PREFIX,
  NAME_PREFIX = NAME_PREFIX,
  MOD_NAME = MOD_NAME,
  MOD_DIR = MOD_DIR,
  GRAPHICS_DIR = GRAPHICS_DIR,

  LAB_CREATED_EFFECT_ID = "ds-create-lab", -- For compatibility with DS
  LAB_REGISTRATIONS_MOD_DATA_NAME = NAME_PREFIX .. "lab-registrations",
  LAB_OVERLAY_ANIMATION_NAME = NAME_PREFIX .. "lab-overlay",
  BIOLAB_OVERLAY_ANIMATION_NAME = NAME_PREFIX .. "biolab-overlay",
  FALLBACK_OVERLAY_ANIMATION_NAME = NAME_PREFIX .. "fallback-overlay",
  FALLBACK_OVERLAY_ENABLED_NAME = NAME_PREFIX .. "fallback-overlay-enabled",
  COLOR_PATTERN_DURATION_NAME = NAME_PREFIX .. "color-pattern-duration",
  COLOR_INTENSITY_NAME = NAME_PREFIX .. "color-intensity",
  UNISON_FLICKER_NAME = NAME_PREFIX .. "unison-flicker",
  LAB_UPDATE_INTERVAL_NAME = NAME_PREFIX .. "lab-update-interval",
}

return consts
