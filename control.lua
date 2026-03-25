local event_handler = require("__core__.lualib.event_handler")

event_handler.add_libraries({
  require("scripts.runtime.control.lab-control"),
})

-- This is for development
if __DebugAdapter then
  require("scripts.runtime.command.ds-bench")
  require("scripts.runtime.command.ds-force-render")
  require("scripts.runtime.command.ds-set-tech")
  require("scripts.runtime.command.ds-showcase")
  require("scripts.runtime.command.ds-test")
end
