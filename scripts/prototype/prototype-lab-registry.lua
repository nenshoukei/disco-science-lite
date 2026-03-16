local Utils = require("scripts.shared.utils")
local config_lab_overlay_settings = require("scripts.shared.config.lab-overlay-settings")

if _G.DiscoSciencePrototypeLabRegistry then
  return _G.DiscoSciencePrototypeLabRegistry
end

--- Registry for LabPrototype and its overlay settings.
local PrototypeLabRegistry = {
  --- Registered LabPrototype name and its overlay settings.
  ---
  --- This table is stored as mod-data prototype for runtime stage.
  --- @type table<string, LabOverlaySettings>
  registered_labs = Utils.table_deep_copy(config_lab_overlay_settings),
}
_G.DiscoSciencePrototypeLabRegistry = PrototypeLabRegistry

--- Resets the registry. Just for testing.
function PrototypeLabRegistry.reset()
  PrototypeLabRegistry.registered_labs = Utils.table_deep_copy(config_lab_overlay_settings)
end

--- Register a new LabPrototype and its overlay settings.
---
--- This overwrites the existing overlay settings with the same name.
---
--- @param lab_name string LabPrototype name
--- @param settings LabOverlaySettings? If not specified, the default settings will be used.
function PrototypeLabRegistry.register(lab_name, settings)
  PrototypeLabRegistry.registered_labs[lab_name] = settings or {} -- Empty settings for default values
end

return PrototypeLabRegistry
