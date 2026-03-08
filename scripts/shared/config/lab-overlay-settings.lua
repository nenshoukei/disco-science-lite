local consts = require("scripts.shared.consts")

--- Default lab overlay settings.
---
--- Key is LabPrototype name.
---
--- @type table<string, LabOverlaySettings>
local config_lab_overlay_settings = {
  lab = {
    animation = consts.LAB_OVERLAY_ANIMATION_NAME,
    scale = 1,
  },
  biolab = {
    animation = consts.BIOLAB_OVERLAY_ANIMATION_NAME,
    scale = 1,
  },
}

return config_lab_overlay_settings
