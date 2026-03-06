local consts = require("scripts.shared.consts")

--- @class TargetLab
--- @field animation string Name of AnimationPrototype to be used as an overlay.
--- @field scale integer Scale of the lab. (Default scale is `1`)

--- This mod's target labs.
---
--- Key is LabPrototype name.
---
--- @type table<string, TargetLab>
local config_target_labs = {
  lab = {
    animation = consts.LAB_OVERLAY_ANIMATION_NAME,
    scale = 1,
  },
  biolab = {
    animation = consts.BIOLAB_OVERLAY_ANIMATION_NAME,
    scale = 1,
  },
}

return config_target_labs
