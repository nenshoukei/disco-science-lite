if _G.DiscoSciencePrototypeLabRegistry then
  return _G.DiscoSciencePrototypeLabRegistry
end

--- Registry for LabPrototype and its overlay settings.
local PrototypeLabRegistry = {
  --- Registered LabPrototype name and its overlay settings.
  ---
  --- This table is stored as mod-data prototype for runtime stage.
  --- @type table<string, LabOverlaySettings>
  registered_labs = {},

  --- LabPrototype names explicitly excluded from colorization.
  ---
  --- This table is stored as mod-data prototype for runtime stage.
  --- @type table<string, boolean>
  excluded_labs = {},
}
_G.DiscoSciencePrototypeLabRegistry = PrototypeLabRegistry

--- Resets the registry. Just for testing.
function PrototypeLabRegistry.reset()
  PrototypeLabRegistry.registered_labs = {}
  PrototypeLabRegistry.excluded_labs = {}
end

--- Exclude a lab from colorization.
---
--- The lab will not receive a color overlay, even when fallback overlay is enabled.
--- Calling `register()` on the same lab name removes the exclusion.
---
--- @param lab_name string LabPrototype name.
function PrototypeLabRegistry.exclude(lab_name)
  PrototypeLabRegistry.registered_labs[lab_name] = nil
  PrototypeLabRegistry.excluded_labs[lab_name] = true
end

--- Register a new LabPrototype and its overlay settings.
---
--- This overwrites the existing overlay settings with the same name.
---
--- When settings.animation is nil, the runtime will use the standard Factorio lab
--- overlay ("mks-dsl-lab-overlay") for this lab. This preserves compatibility with
--- the original DiscoScience mod API where prepareLab(lab) without an animation
--- always uses the vanilla lab overlay shape.
---
--- @param lab_name string LabPrototype name
--- @param settings LabOverlaySettings? If not specified, both animation and scale are nil.
function PrototypeLabRegistry.register(lab_name, settings)
  settings = settings or {}
  PrototypeLabRegistry.excluded_labs[lab_name] = nil
  PrototypeLabRegistry.registered_labs[lab_name] = settings
end

return PrototypeLabRegistry
