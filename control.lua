local event_handler = require("__core__.lualib.event_handler")

event_handler.add_libraries({
  require("scripts.runtime.control.lab-control"),
})

if settings.startup[ "mks-dsl-is-development" --[[$IS_DEVELOPMENT_NAME]] ].value then
  require("scripts.runtime.command.ds-bench")
  require("scripts.runtime.command.ds-force-render")
  require("scripts.runtime.command.ds-set-tech")
  require("scripts.runtime.command.ds-showcase")
  require("scripts.runtime.command.ds-test")
end
