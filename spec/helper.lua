-- Helper functions for busted tests
-- This file is automatically loaded by busted

local cjson = require("cjson.safe")
local serpent = require("serpent")

_G.serpent = serpent

--- @diagnostic disable-next-line: missing-fields
_G.helpers = {
  table_to_json = function (tbl)
    return cjson.encode(tbl)
  end,
  json_to_table = function (json_string)
    return cjson.decode(json_string)
  end,
}

local missing_mock_check = {
  __index = function (_, key)
    error("Missing mock for " .. key)
  end,
}

_G.defines = setmetatable({
  render_mode = {
    chart = 1,
    game = 2,
  },
  entity_status = {
    normal    = 1,
    working   = 2,
    low_power = 3,
  },
  events = setmetatable({
    on_gui_click = 1,
    on_gui_closed = 2,
    on_gui_opened = 3,
    on_gui_selected_tab_changed = 4,
    on_lua_shortcut = 100,
    on_player_created = 200,
    on_player_removed = 201,
    on_player_cursor_stack_changed = 202,
  }, missing_mock_check),
}, missing_mock_check)

local function reset_mocks()
  _G.log = function () end

  --- @diagnostic disable-next-line: missing-fields
  _G.prototypes = {
    shortcut = {},
    item = {},
    mod_data = {},
  }

  --- @diagnostic disable-next-line: missing-fields
  _G.game = {
    players = {},
  }

  --- @diagnostic disable-next-line: missing-fields
  _G.script = {
    register_metatable = function () end,
    register_on_object_destroyed = function () end,
    on_event = function () end,
  }

  --- @diagnostic disable-next-line: missing-fields
  _G.settings = ({
    startup = {
      [ "mks-dsl-fallback-overlay-enabled" --[[$FALLBACK_OVERLAY_ENABLED_NAME]] ] = { value = true },
    },
    global = {
      [ "mks-dsl-color-pattern-duration" --[[$COLOR_PATTERN_DURATION_NAME]] ] = { value = 180 },
      [ "mks-dsl-color-intensity" --[[$COLOR_INTENSITY_NAME]] ]               = { value = 100 },
      [ "mks-dsl-unison-flicker" --[[$UNISON_FLICKER_NAME]] ]                 = { value = false },
      [ "mks-dsl-lab-update-interval" --[[$LAB_UPDATE_INTERVAL_NAME]] ]       = { value = 6 },
    },
  })
end

reset_mocks()

return {
  reset_mocks = reset_mocks,
}
