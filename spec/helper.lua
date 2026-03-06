-- Helper functions for busted tests
-- This file is automatically loaded by busted

local cjson = require("cjson.safe")
local serpent = require("serpent")

_G.serpent = serpent

-- Mock Factorio globals for testing
local function reset_mocks()
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
    on_event = function () end,
  }

  -- _G.storage = {}

  _G.log = function () end

  -- Mock settings
  _G.settings = {
    startup = {
    },
  }

  _G.defines = {
    events = setmetatable({
      on_gui_click = 1,
      on_gui_closed = 2,
      on_gui_opened = 3,
      on_gui_selected_tab_changed = 4,
      on_lua_shortcut = 100,
      on_player_created = 200,
      on_player_removed = 201,
      on_player_cursor_stack_changed = 202,
    }, {
      __index = function (_, key)
        error("Missing mock for defines.events." .. key)
      end,
    }),
  }

  -- Mock helpers functions
  _G.helpers = {
    table_to_json = function (tbl)
      return cjson.encode(tbl)
    end,
    json_to_table = function (json_string)
      return cjson.decode(json_string)
    end,
  }
end

reset_mocks()

return {
  reset_mocks = reset_mocks,
}
