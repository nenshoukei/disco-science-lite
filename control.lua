local event_handler = require("__core__.lualib.event_handler")

event_handler.add_libraries({
  require("scripts.runtime.control.lab-control"),
})

-- This is for benchmarking on development
if script.active_mods["debugadapter"] then
  require("scripts.runtime.control.benchmark")
end
