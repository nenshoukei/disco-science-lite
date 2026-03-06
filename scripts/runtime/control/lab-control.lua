local RemoteInterface = require("scripts.runtime.remote-interface")
local ColorRegistry = require("scripts.runtime.color-registry")

--- @class LabControl : event_handler
local LabControl = {}

--- @type ColorRegistry
local color_registry

function LabControl.on_init()
  color_registry = ColorRegistry.new()

  storage.color_registry = color_registry
end

function LabControl.on_load()
  color_registry = storage.color_registry or ColorRegistry.new()
end

function LabControl.add_remote_interface()
  assert(storage, "storage is not initialized")
  RemoteInterface.bind_storage(storage --[[@as DiscoScienceStorage]])

  -- Compatible with original DiscoScience interface
  remote.add_interface("DiscoScience", RemoteInterface.functions)
end

return LabControl
