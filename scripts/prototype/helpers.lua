local Helpers = {}

--- Geometric properties to copy from a source layer to a new layer or animation.
--- Note: `lines_per_file` is excluded because it is only relevant for multi-file layers.
local GEOMETRIC_PROPERTIES = {
  "size", "width", "height", "x", "y", "position",
  "shift", "scale", "run_mode", "frame_count", "line_length",
  "animation_speed", "max_advance", "repeat_count", "frame_sequence",
}

--- Copy geometric properties from a source animation to a new animation.
---
--- @param source data.Animation
--- @return data.Animation
function Helpers.copy_geometric_properties(source)
  local result = {}
  for i = 1, #GEOMETRIC_PROPERTIES do
    local prop = GEOMETRIC_PROPERTIES[i]
    result[prop] = source[prop]
  end
  return result
end

return Helpers
