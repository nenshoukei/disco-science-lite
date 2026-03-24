local event_handler = require("__core__.lualib.event_handler")

event_handler.add_libraries({
  require("scripts.runtime.control.lab-control"),
})

-- This is for development
if __DebugAdapter then
  require("scripts.runtime.control.dev.ds-bench")
end
