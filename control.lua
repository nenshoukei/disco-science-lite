local event_handler = require("__core__.lualib.event_handler")
local Settings = require("scripts.shared.settings")

event_handler.add_libraries({
  require("scripts.runtime.control.lab-control"),
})

if Settings.is_development then
  require("scripts.runtime.command.ds-bench")
  require("scripts.runtime.command.ds-bench-color")
  require("scripts.runtime.command.ds-force-render")
  require("scripts.runtime.command.ds-set-tech")
  require("scripts.runtime.command.ds-showcase")
  require("scripts.runtime.command.ds-test")
end

if script.active_mods["factorio-test"] then
  require("__factorio-test__/init")(
    {
      "e2e.lab-overlay_test",
    },
    {
      load_luassert = true,
    }
  )
end
