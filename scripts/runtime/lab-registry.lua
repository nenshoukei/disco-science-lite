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
    --- Lab overlay settings by LabPrototype name.
    --- @type table<string, LabOverlaySettings>
    overlay_settings = {},
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
--- If `settings` is passed, it will override the existing settings with the same name.
---
--- If `settings` is not passed, the default overlay settings are used. (See [LabOverlaySettings](lua://LabOverlaySettings))
---
--- @param lab_name string LabPrototype name.
--- @param settings LabOverlaySettings? Settings for the lab overlay.
function LabRegistry:register(lab_name, settings)
  self.overlay_settings[lab_name] = settings or {}
end

--- Set scale of a lab overlay.
---
--- If the given lab has not been registered yet, it will be registered with the default lab overlay settings.
--- (See [LabOverlaySettings](lua://LabOverlaySettings))
---
--- If the lab was excluded, the exclusion is cancelled.
---
--- @param lab_name string LabPrototype name.
--- @param scale integer Scale of the lab. (Default scale is `1`)
function LabRegistry:set_scale(lab_name, scale)
  self.scale_overrides[lab_name] = scale
  self.excluded_labs[lab_name] = nil
  local settings = self.overlay_settings[lab_name]
  if settings then
    settings.scale = scale
  else
    -- Automatically creates a LabOverlaySettings with the default values (nil).
    self.overlay_settings[lab_name] = {
      scale = scale,
    }
  end
end

--- Get the LabOverlaySettings for the given lab name.
---
--- Returns `nil` for excluded labs.
---
--- @param lab_name string LabPrototype name.
--- @return LabOverlaySettings|nil
function LabRegistry:get_overlay_settings(lab_name)
  return self.overlay_settings[lab_name]
end

--- Returns whether the given lab is excluded from colorization.
---
--- @param lab_name string LabPrototype name.
--- @return boolean
function LabRegistry:is_excluded(lab_name)
  return self.excluded_labs[lab_name] == true
end

--- Load lab settings from the mod-data prototype.
---
--- Always replaces existing settings with a fresh copy from the prototype data,
--- then re-applies runtime scale overrides on top.
---
--- Excluded labs are removed from overlay_settings and stored in excluded_labs.
function LabRegistry:load_prototype_settings()
  -- Load excluded labs set.
  local excluded_mod_data = prototypes.mod_data[ "mks-dsl-excluded-labs" --[[$EXCLUDED_LABS_MOD_DATA_NAME]] ]
  if excluded_mod_data then
    self.excluded_labs = excluded_mod_data.data --[[@as table<string, boolean>]]
  else
    self.excluded_labs = {}
  end

  local overlay_mod_data = prototypes.mod_data[ "mks-dsl-lab-overlay-settings" --[[$LAB_OVERLAY_SETTINGS_MOD_DATA_NAME]] ]
  if overlay_mod_data then
    self.overlay_settings = Utils.table_deep_copy(overlay_mod_data.data --[[@as table<string, LabOverlaySettings>]])
  else
    self.overlay_settings = {}
  end

  -- Remove excluded labs from overlay_settings.
  for lab_name in pairs(self.excluded_labs) do
    self.overlay_settings[lab_name] = nil
  end

  -- Re-apply runtime scale overrides on top of prototype data (skip excluded labs).
  for lab_name, scale in pairs(self.scale_overrides) do
    if not self.excluded_labs[lab_name] then
      local settings = self.overlay_settings[lab_name]
      if settings then
        settings.scale = scale
      else
        self.overlay_settings[lab_name] = { scale = scale }
      end
    end
  end
end

return LabRegistry
