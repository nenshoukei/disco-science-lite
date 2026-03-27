-- Helper functions for busted tests
-- This file is automatically loaded by busted

local cjson = require("cjson.safe")
local serpent = require("serpent")
local table_deep_copy = require("scripts.shared.utils").table_deep_copy
local Settings = require("scripts.shared.settings")
local AnimationAssertion = require("spec.helper.animation-assertion")
require("spec.helper.rendering")

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
  target_type = {
    entity = 1,
  },
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
    on_tick = 1,
    on_gui_click = 2,
    on_gui_closed = 3,
    on_gui_opened = 4,
    on_gui_selected_tab_changed = 5,
    on_lua_shortcut = 100,
    on_player_created = 200,
    on_player_removed = 201,
    on_player_cursor_stack_changed = 202,
    on_player_changed_position = 203,
    on_player_changed_surface = 204,
    on_player_changed_force = 205,
    on_player_display_resolution_changed = 206,
    on_player_left_game = 207,
    on_player_kicked = 208,
    on_research_started = 300,
    on_research_finished = 301,
    on_research_cancelled = 302,
    on_surface_cleared = 400,
    on_surface_deleted = 401,
    on_script_trigger_effect = 500,
    on_object_destroyed = 501,
    script_raised_teleported = 502,
    on_runtime_mod_setting_changed = 503,
  }, missing_mock_check),
}, missing_mock_check)

local function reset_mocks()
  _G.log = function () end

  --- @diagnostic disable-next-line: missing-fields
  _G.prototypes = {
    shortcut = {},
    item = {},
    mod_data = {},
    technology = {},
  }

  --- @diagnostic disable-next-line: missing-fields
  _G.game = {
    tick = 0,
    players = {},
    forces = {},
    surfaces = {},
    get_player = function (index) return _G.game.players[index] end,
  }

  --- @diagnostic disable-next-line: missing-fields
  _G.script = {
    register_metatable = function () end,
    register_on_object_destroyed = function () end,
    on_event = function () end,
    on_nth_tick = function () end,
  }

  --- @diagnostic disable-next-line: missing-fields
  _G.remote = {
    add_interface = function () end,
  }

  --- @diagnostic disable-next-line: missing-fields
  _G.commands = {
    add_command = function () end,
  }

  --- @diagnostic disable-next-line: missing-fields
  _G.settings = ({
    startup = {
      [ "mks-dsl-fallback-overlay-enabled" --[[$FALLBACK_OVERLAY_ENABLED_NAME]] ] = { value = true },
      [ "mks-dsl-disable-lab-blinking" --[[$DISABLE_LAB_BLINKING_NAME]] ] = { value = false },
      [ "mks-dsl-is-development" --[[$IS_DEVELOPMENT_NAME]] ] = { value = true },
    },
    global = {
      [ "mks-dsl-color-pattern-duration" --[[$COLOR_PATTERN_DURATION_NAME]] ] = { value = 180 --[[$DEFAULT_COLOR_PATTERN_DURATION]] },
      [ "mks-dsl-color-intensity" --[[$COLOR_INTENSITY_NAME]] ]               = { value = 100 },
      [ "mks-dsl-max-updates-per-tick" --[[$MAX_UPDATES_PER_TICK_NAME]] ]     = { value = 500 --[[$DEFAULT_MAX_UPDATES_PER_TICK]] },
    },
  })

  _G.mods = {}

  --- @diagnostic disable-next-line: missing-fields
  _G.data = {
    raw = { lab = {}, animation = {} },
    extend = function (self, defs)
      for _, def in ipairs(defs) do
        local type_table = _G.data.raw[def.type]
        if not type_table then
          _G.data.raw[def.type] = {}
          type_table = _G.data.raw[def.type]
        end
        type_table[def.name] = def
      end
    end,
  }

  Settings.reload()
end

local function load_animation_definitions()
  package.loaded["scripts.prototype.definitions.animation"] = nil
  require("scripts.prototype.definitions.animation")
end

reset_mocks()

return {
  reset_mocks = reset_mocks,
  load_animation_definitions = load_animation_definitions,
  table_deep_copy = table_deep_copy,
  assert_animation = AnimationAssertion,
}
