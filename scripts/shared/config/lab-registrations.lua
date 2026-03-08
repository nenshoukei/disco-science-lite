local consts = require("scripts.shared.consts")

--- Default lab registrations provided by this mod.
---
--- Key is LabPrototype name.
---
--- @type table<string, LabRegistration>
local config_lab_registrations = {
  lab = {
    animation = consts.LAB_OVERLAY_ANIMATION_NAME,
    scale = 1,
  },
  biolab = {
    animation = consts.BIOLAB_OVERLAY_ANIMATION_NAME,
    scale = 1,
  },
}

return config_lab_registrations
