if _G.DiscoSciencePrototypeLabRegistry then
  return _G.DiscoSciencePrototypeLabRegistry
end

--- Registry for LabPrototype registrations.
local PrototypeLabRegistry = {
  --- Registered LabPrototype name and its registration.
  ---
  --- This table is stored as mod-data prototype for runtime stage.
  --- @type table<string, LabRegistration>
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

--- Register a new LabPrototype and its registration.
---
--- This overwrites the existing registration with the same name.
---
--- When registration.animation is nil, the runtime will use the standard Factorio lab
--- overlay ("mks-dsl-lab-overlay") for this lab. This preserves compatibility with
--- the original DiscoScience mod API where prepareLab(lab) without an animation
--- always uses the vanilla lab overlay shape.
---
--- @param lab_name string LabPrototype name
--- @param registration LabRegistration? If not specified, both animation and scale are nil.
function PrototypeLabRegistry.register(lab_name, registration)
  registration = registration or {}
  PrototypeLabRegistry.excluded_labs[lab_name] = nil
  PrototypeLabRegistry.registered_labs[lab_name] = registration
end

--- Check all registrations have valid animations.
---
--- * If animation is not defined, use general overlay instead.
--- * If companion is not defined, companion is ignored by setting `nil`.
---
function PrototypeLabRegistry.validate_registrations()
  local animation_prototypes = data.raw["animation"]
  local invalid_registrations = {}
  for name, registration in pairs(PrototypeLabRegistry.registered_labs) do
    local animation = registration.animation
    if animation and not animation_prototypes[animation] then
      log('Disco Science Lite: Registered lab "' .. name .. '" has animation "' .. animation .. '", but it is not defined. Falls back to the general overlay.')
      table.insert(invalid_registrations, name)
    else
      local companion = registration.companion
      if companion and not animation_prototypes[companion] then
        log('Disco Science Lite: Registered lab "' .. name .. '" has companion "' .. companion .. '", but it is not defined. Ignored.')
        registration.companion = nil
      end
    end
  end

  for _, name in ipairs(invalid_registrations) do
    PrototypeLabRegistry.registered_labs[name] = nil
  end
end

return PrototypeLabRegistry
