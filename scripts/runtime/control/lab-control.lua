local RemoteInterface = require("scripts.runtime.remote-interface")
local ColorRegistry = require("scripts.runtime.color-registry")
local LabOverlayRenderer = require("scripts.runtime.lab-overlay-renderer")

--- @class LabControl : event_handler
local LabControl = {}

--- @type LabOverlayRenderer
local lab_overlay_renderer

local function initialize()
  lab_overlay_renderer = storage.lab_overlay_renderer or LabOverlayRenderer.new(ColorRegistry.new())
  storage.lab_overlay_renderer = lab_overlay_renderer

  script.on_nth_tick(2, lab_overlay_renderer:get_tick_function())
end

function LabControl.on_init()
  initialize()
end

function LabControl.on_load()
  initialize()
end

function LabControl.add_remote_interface()
  assert(lab_overlay_renderer, "Not initialized")
  RemoteInterface.bind_storage(storage --[[@as DiscoScienceStorage]])

  -- Compatible with original DiscoScience interface
  remote.add_interface("DiscoScience", RemoteInterface.functions)
end

return LabControl
