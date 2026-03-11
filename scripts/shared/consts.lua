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

  -- animations
  LAB_OVERLAY_ANIMATION_NAME = NAME_PREFIX .. "lab-overlay",
  BIOLAB_OVERLAY_ANIMATION_NAME = NAME_PREFIX .. "biolab-overlay",
  GENERAL_OVERLAY_ANIMATION_NAME = NAME_PREFIX .. "general-overlay",

  -- graphics
  LAB_OVERLAY_GRAPHIC_FILE_NAME = GRAPHICS_DIR .. "lab-overlay.png",
  BIOLAB_OVERLAY_GRAPHIC_FILE_NAME = GRAPHICS_DIR .. "biolab-overlay.png",
  GENERAL_OVERLAY_GRAPHIC_FILE_NAME = GRAPHICS_DIR .. "general-overlay.png",

  -- settings
  FALLBACK_OVERLAY_ENABLED_NAME = NAME_PREFIX .. "fallback-overlay-enabled",
  COLOR_PATTERN_DURATION_NAME = NAME_PREFIX .. "color-pattern-duration",
  COLOR_INTENSITY_NAME = NAME_PREFIX .. "color-intensity",
  UNISON_FLICKER_NAME = NAME_PREFIX .. "unison-flicker",
  LAB_UPDATE_INTERVAL_NAME = NAME_PREFIX .. "lab-update-interval",

  -- Size of each chunk in tiles. Matches Factorio's built-in chunk size.
  CHUNK_SIZE = 32,
  INV_CHUNK_SIZE = 1 / 32,

  -- Margin of PlayerView boundaries
  VIEW_RECT_MARGIN = 6, -- tiles

  -- ChunkMapEntry filed indices
  CE_SURFACE = 1,
  CE_CX = 2,
  CE_CY = 3,
  CE_OVERLAY = 4,

  -- PlayerView field indices
  PV_VALID = 1,
  PV_SURFACE = 2,
  PV_LEFT = 3,
  PV_TOP = 4,
  PV_RIGHT = 5,
  PV_BOTTOM = 6,

  -- LabOverlay field indices
  OV_ENTITY = 1,
  OV_ANIMATION = 2,
  OV_X = 3,
  OV_Y = 4,
  OV_RECT = 5,
  OV_VISIBLE = 6,
  OV_UNIT_NUM = 7,
  OV_FORCE_INDEX = 8,

  -- ForceState field indices
  FS_CURRENT_RESEARCH = 1,
  FS_COLORS = 2,
  FS_N_COLORS = 3,
  FS_PX = 4,
  FS_PY = 5,
}

return consts
