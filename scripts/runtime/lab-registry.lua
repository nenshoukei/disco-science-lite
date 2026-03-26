local Utils = require("scripts.shared.utils")

--- @class LabRegistry
local LabRegistry = {}
LabRegistry.__index = LabRegistry

--- Constructor
---
--- @param lab_scale_overrides table<string, number>?
--- @return LabRegistry
function LabRegistry.new(lab_scale_overrides)
  --- @class LabRegistry
  local self = {
    --- Registrations by LabPrototype name.
    --- @type table<string, LabRegistration>
    registered_labs = {},
    --- Runtime scale overrides persisted in storage. Reference to storage.lab_scale_overrides.
    --- @type table<string, number>
    scale_overrides = lab_scale_overrides or {},
    --- Labs excluded from colorization. Loaded from prototype mod-data on each load.
    --- @type table<string, boolean>
    excluded_labs = {},
  }
  return setmetatable(self, LabRegistry)
end

--- Register a lab type to be colorized by this mod.
---
--- If `registration` is passed, it will override the existing registration with the same name.
---
--- If `registration` is not passed, the vanilla lab overlay is used.
---
--- @param lab_name string LabPrototype name.
--- @param registration LabRegistration? Registration for the lab.
function LabRegistry:register(lab_name, registration)
  self.registered_labs[lab_name] = registration or {}
end

--- Set scale of a lab overlay.
---
--- If the given lab has not been registered yet, it will be registered with the default registration values.
---
--- If the lab was excluded, the exclusion is cancelled.
---
--- @param lab_name string LabPrototype name.
--- @param scale integer Scale of the lab. (Default scale is `1`)
function LabRegistry:set_scale(lab_name, scale)
  self.scale_overrides[lab_name] = scale
  self.excluded_labs[lab_name] = nil
  local registration = self.registered_labs[lab_name]
  if registration then
    registration.scale = scale
  else
    -- Automatically creates a LabRegistration with the default values (nil).
    self.registered_labs[lab_name] = {
      scale = scale,
    }
  end
end

--- Get the LabRegistration for the given lab name.
---
--- Returns `nil` for excluded labs.
---
--- @param lab_name string LabPrototype name.
--- @return LabRegistration|nil
function LabRegistry:get_registration(lab_name)
  return self.registered_labs[lab_name]
end

--- Returns whether the given lab is excluded from colorization.
---
--- @param lab_name string LabPrototype name.
--- @return boolean
function LabRegistry:is_excluded(lab_name)
  return self.excluded_labs[lab_name] == true
end

--- Load lab registrations from the mod-data prototype.
---
--- Always replaces existing registrations with a fresh copy from the prototype data,
--- then re-applies runtime scale overrides on top.
---
--- Excluded labs are removed from registered_labs and stored in excluded_labs.
function LabRegistry:load_prototype_registrations()
  local mod_data = prototypes.mod_data[ "mks-dsl-prototype-data" --[[$PROTOTYPE_DATA_MOD_DATA_NAME]] ]
  if mod_data then
    local data = mod_data.data --[[@as DiscoSciencePrototypeData]]
    self.excluded_labs = data.excluded_labs
    self.registered_labs = Utils.table_deep_copy(data.registered_labs)
  else
    self.excluded_labs = {}
    self.registered_labs = {}
  end

  -- Remove excluded labs from registered_labs.
  for lab_name in pairs(self.excluded_labs) do
    self.registered_labs[lab_name] = nil
  end

  -- Re-apply runtime scale overrides on top of prototype data (skip excluded labs).
  for lab_name, scale in pairs(self.scale_overrides) do
    if not self.excluded_labs[lab_name] then
      local registration = self.registered_labs[lab_name]
      if registration then
        registration.scale = scale
      else
        self.registered_labs[lab_name] = { scale = scale }
      end
    end
  end
end

return LabRegistry
