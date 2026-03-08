local consts = require("scripts.shared.consts")
local config_target_labs = require("scripts.shared.config.target-labs")
local Utils = require("scripts.shared.utils")

--- @class TargetLabRegistry
local TargetLabRegistry = {}
TargetLabRegistry.__index = TargetLabRegistry

if script then
  script.register_metatable("TargetLabRegistry", TargetLabRegistry)
end

local LAB_OVERLAY_ANIMATION_NAME = consts.LAB_OVERLAY_ANIMATION_NAME
local LAB_REGISTRATIONS_MOD_DATA_NAME = consts.LAB_REGISTRATIONS_MOD_DATA_NAME

--- Constructor
---
--- @return TargetLabRegistry
function TargetLabRegistry.new()
  --- @class TargetLabRegistry
  local self = {
    --- Dictionary of target labs. Key is LabPrototype name.
    --- @type table<string, TargetLab>
    labs = Utils.table_deep_copy(config_target_labs),
  }
  return setmetatable(self, TargetLabRegistry)
end

--- Add a new target lab type.
---
--- @param lab_name string LabPrototype name.
--- @param target_lab TargetLab Settings for the lab.
function TargetLabRegistry:add(lab_name, target_lab)
  self.labs[lab_name] = target_lab
end

--- Set scale of the target lab.
---
--- If the given lab is not a target, it will register the lab as a target with the default overlay.
---
--- @param lab_name string LabPrototype name.
--- @param scale integer Scale of the lab. (Default scale is `1`)
function TargetLabRegistry:set_scale(lab_name, scale)
  local target_lab = self.labs[lab_name]
  if target_lab then
    target_lab.scale = scale
  else
    -- Automatically creates a TargetLab with the default overlay.
    self.labs[lab_name] = {
      animation = LAB_OVERLAY_ANIMATION_NAME,
      scale = scale,
    }
  end
end

--- Get the target lab settings for the given lab name.
---
--- @param lab_name string LabPrototype name.
--- @return TargetLab|nil
function TargetLabRegistry:get(lab_name)
  return self.labs[lab_name]
end

--- Load lab registrations from the mod-data prototype written by DiscoScience.registerLab().
---
--- Only entries that include an animation field are applied (i.e. registerLab registrations).
--- Entries written by prepareLab (which have no animation) are skipped so they do not
--- overwrite animation values already set in the registry by addTargetLab remote calls.
--- Existing entries not present in the mod-data are preserved.
function TargetLabRegistry:apply_prototype_registrations()
  local mod_data = prototypes["mod-data"][LAB_REGISTRATIONS_MOD_DATA_NAME]
  if not mod_data then return end
  local labs = self.labs
  --- @type table<string, {animation: string, scale: integer}>
  local registrations = mod_data.data --[[@as table<string, {animation: string, scale: integer}>]]
  for lab_name, reg in pairs(registrations) do
    local animation = reg.animation
    if animation then
      labs[lab_name] = {
        animation = animation,
        scale = reg.scale or 1,
      }
    end
  end
end

return TargetLabRegistry
