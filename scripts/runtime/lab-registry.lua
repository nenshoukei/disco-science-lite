local consts = require("scripts.shared.consts")
local config_lab_registrations = require("scripts.shared.config.lab-registrations")
local Utils = require("scripts.shared.utils")

--- @class LabRegistry
local LabRegistry = {}
LabRegistry.__index = LabRegistry

if script then
  script.register_metatable("LabRegistry", LabRegistry)
end

--- Constructor
---
--- @return LabRegistry
function LabRegistry.new()
  --- @class LabRegistry
  local self = {
    --- Lab registrations by LabPrototype name.
    --- @type table<string, LabRegistration>
    labs = Utils.table_deep_copy(config_lab_registrations),
  }
  return setmetatable(self, LabRegistry)
end

--- Add a new lab registration.
---
--- @param lab_name string LabPrototype name.
--- @param registration LabRegistration
function LabRegistry:add(lab_name, registration)
  self.labs[lab_name] = registration
end

--- Set scale of a lab registration.
---
--- If the given lab has no registration yet, it will be registered with the default overlay.
---
--- @param lab_name string LabPrototype name.
--- @param scale integer Scale of the lab. (Default scale is `1`)
function LabRegistry:set_scale(lab_name, scale)
  local registration = self.labs[lab_name]
  if registration then
    registration.scale = scale
  else
    -- Automatically creates a registration with the default overlay.
    self.labs[lab_name] = {
      animation = consts.LAB_OVERLAY_ANIMATION_NAME,
      scale = scale,
    }
  end
end

--- Get the registration for the given lab name.
---
--- @param lab_name string LabPrototype name.
--- @return LabRegistration|nil
function LabRegistry:get(lab_name)
  return self.labs[lab_name]
end

--- Load lab registrations from the mod-data prototype written by DiscoScience.prepareLab().
---
--- Does not overwrite any existing values since they are set by remote calls for overriding the prototype values.
function LabRegistry:apply_prototype_registrations()
  local mod_data = prototypes["mod-data"][consts.LAB_REGISTRATIONS_MOD_DATA_NAME]
  if not mod_data then return end
  local registrations = mod_data.data --[[@as table<string, LabRegistration>]]

  local labs = self.labs
  for lab_name, reg in pairs(registrations) do
    if not labs[lab_name] then
      labs[lab_name] = {
        animation = reg.animation,
        scale = reg.scale or 1,
      }
    end
  end
end

return LabRegistry
