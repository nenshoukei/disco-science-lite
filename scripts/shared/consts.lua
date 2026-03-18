local PREFIX = "mks-dsl"
local NAME_PREFIX = PREFIX .. "-"
local MOD_NAME = "disco-science-lite"
local MOD_DIR = "__" .. MOD_NAME .. "__/"
local GRAPHICS_DIR = MOD_DIR .. "graphics/"

--- Constants embedded as literals.
---
--- Special syntax `123 --[[$CONST_NAME]]` where `consts.CONST_NAME = 123`, keeps it updated with the current value.
---
--- Run `make consts` every time after changing any constant value.
---
--- @class consts
local consts = {
  PREFIX = PREFIX,
  NAME_PREFIX = NAME_PREFIX,
  MOD_NAME = MOD_NAME,
  MOD_DIR = MOD_DIR,
  GRAPHICS_DIR = GRAPHICS_DIR,

  -- effect_id
  LAB_CREATED_EFFECT_ID = "ds-create-lab", -- For compatibility with DS

  -- mod-data
  LAB_OVERLAY_SETTINGS_MOD_DATA_NAME = NAME_PREFIX .. "lab-overlay-settings",
  INGREDIENT_COLORS_MOD_DATA_NAME = NAME_PREFIX .. "ingredient-colors",
  EXCLUDED_LABS_MOD_DATA_NAME = NAME_PREFIX .. "excluded-labs",

  -- animations
  LAB_OVERLAY_ANIMATION_NAME = NAME_PREFIX .. "lab-overlay",
  GENERAL_OVERLAY_ANIMATION_NAME = NAME_PREFIX .. "general-overlay",

  -- settings
  FALLBACK_OVERLAY_ENABLED_NAME = NAME_PREFIX .. "fallback-overlay-enabled",
  DISABLE_LAB_BLINKING_NAME = NAME_PREFIX .. "disable-lab-blinking",
  COLOR_PATTERN_DURATION_NAME = NAME_PREFIX .. "color-pattern-duration",
  COLOR_INTENSITY_NAME = NAME_PREFIX .. "color-intensity",
  MAX_UPDATES_PER_TICK_NAME = NAME_PREFIX .. "max-updates-per-tick",

  --- Size of each chunk in tiles. Matches Factorio's built-in chunk size.
  CHUNK_SIZE = 32,

  --- Pixels per tile.
  TILE_SIZE = 32,
  --- Pixels per two tiles. (TILE_SIZE * 2)
  TWO_TILE_SIZE = 64,

  --- Margin of player view boundaries in tiles
  VIEW_RECT_MARGIN = 6,
}

return consts
