local Utils = require("scripts.shared.utils")
local config_lab_overlay_settings = require("scripts.shared.config.lab-overlay-settings")

--- Registry for LabPrototype and its overlay settings.
local LabPrototypeRegistry = {
  --- Registered LabPrototype name and its overlay settings.
  ---
  --- This table is stored as mod-data prototype for runtime stage.
  --- @type table<string, LabOverlaySettings>
  registered_labs = Utils.table_deep_copy(config_lab_overlay_settings),
}

--- Resets the registry. Just for testing.
function LabPrototypeRegistry.reset()
  LabPrototypeRegistry.registered_labs = Utils.table_deep_copy(config_lab_overlay_settings)
end

--- Register a new LabPrototype and its overlay settings.
---
--- This overwrites the existing overlay settings with the same name.
---
--- @param lab_name string LabPrototype name
--- @param settings LabOverlaySettings? If not specified, the default settings will be used.
function LabPrototypeRegistry.register(lab_name, settings)
  LabPrototypeRegistry.registered_labs[lab_name] = settings or {} -- Empty settings for default values
end

return LabPrototypeRegistry
