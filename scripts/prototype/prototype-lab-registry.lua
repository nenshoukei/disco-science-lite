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

  --- Overlay detection entries: animation name + set of filenames to match.
  --- @type OverlayDetection[]
  overlay_detections = {},
}
_G.DiscoSciencePrototypeLabRegistry = PrototypeLabRegistry

--- An overlay detection entry mapping filenames to an animation prototype name.
--- @class (exact) OverlayDetection
--- @field [1] string  animation prototype name
--- @field [2] table<string, boolean>  set of filenames to match against on_animation

--- Collect all filenames and the max effective dimension from an animation tree.
---
--- Filenames are mapped to the scale of the animation node that contains them.
--- max_dim[1] tracks the running maximum of max(width, height) * scale across nodes
--- that have width and height defined.
---
--- @param animation data.Animation
--- @param filenames table<string, number>  output: filename -> scale
--- @param max_dim number[]  mutable box: max_dim[1] = running max effective dimension
local function collect_filenames(animation, filenames, max_dim)
  local scale = animation.scale or 1.0
  local w = animation.width
  local h = animation.height
  if w and h then
    local effective = math.max(w, h) * scale
    if effective > max_dim[1] then
      max_dim[1] = effective
    end
  end
  if animation.filename then
    filenames[animation.filename] = scale
  end
  local fn_list = animation.filenames
  if fn_list then
    for i = 1, #fn_list do
      filenames[fn_list[i]] = scale
    end
  end
  local layers = animation.layers
  if layers then
    for i = 1, #layers do
      collect_filenames(layers[i], filenames, max_dim)
    end
  end
end

--- Detect overlay animation and scale for a lab based on its on_animation filenames.
---
--- Priority:
---   1. Registered detection: matched by filename → animation_name, layer_scale / 0.5
---   2. General overlay fallback: unmatched but width/height available →
---      "mks-dsl-general-overlay", max_effective_dim / general_effective_dim
---   3. No match → nil, nil
---
--- Returns nil, nil when data is unavailable (e.g. test environment without mock).
---
--- @param lab_name string
--- @return string?, number?
local function detect_overlay(lab_name)
  if not data then return nil, nil end
  local lab_proto = data.raw["lab"] and data.raw["lab"][lab_name]
  if not lab_proto or not lab_proto.on_animation then return nil, nil end

  local filenames = {} --- @type table<string, number>
  local max_dim = { 0 }
  collect_filenames(lab_proto.on_animation, filenames, max_dim)

  -- Try registered detections first
  local detections = PrototypeLabRegistry.overlay_detections
  for i = 1, #detections do
    local detection = detections[i]
    local animation_name = detection[1]
    local detection_filenames = detection[2]
    for fn in pairs(detection_filenames) do
      local layer_scale = filenames[fn]
      if layer_scale then
        return animation_name, layer_scale / 0.5
      end
    end
  end

  -- Fall back to general overlay, scaled to fit the lab's animation dimensions
  if max_dim[1] > 0 then
    local general = data.raw["animation"] and data.raw["animation"][ "mks-dsl-general-overlay" --[[$GENERAL_OVERLAY_ANIMATION_NAME]] ]
    if general then
      local general_eff = math.max(general.width, general.height) * (general.scale or 0.5)
      return "mks-dsl-general-overlay" --[[$GENERAL_OVERLAY_ANIMATION_NAME]], max_dim[1] / general_eff
    end
  end

  return nil, nil
end

--- Resets the registry. Just for testing.
function PrototypeLabRegistry.reset()
  PrototypeLabRegistry.registered_labs = {}
  PrototypeLabRegistry.overlay_detections = {}
end

--- Register an overlay animation to be auto-detected by filename.
---
--- When a lab's on_animation contains any of the given filenames and no explicit
--- animation is set in register(), the animation (and a scale derived from the
--- matching layer's scale) are automatically applied.
---
--- @param animation_name string  AnimationPrototype name
--- @param filenames string[]  filenames to match against on_animation
function PrototypeLabRegistry.add_overlay_detection(animation_name, filenames)
  local filename_set = {} --- @type table<string, boolean>
  for i = 1, #filenames do
    filename_set[filenames[i]] = true
  end
  local detections = PrototypeLabRegistry.overlay_detections
  detections[#detections + 1] = { animation_name, filename_set }
end

--- Register a new LabPrototype and its overlay settings.
---
--- This overwrites the existing overlay settings with the same name.
---
--- When settings.animation is nil, the overlay animation is auto-detected from the
--- lab's on_animation filenames. If no registered detection matches, falls back to
--- "mks-dsl-general-overlay" scaled to fit the lab's animation dimensions.
--- The scale is also auto-calculated from the matching result if settings.scale is nil.
---
--- @param lab_name string LabPrototype name
--- @param settings LabOverlaySettings? If not specified, both animation and scale are auto-detected.
function PrototypeLabRegistry.register(lab_name, settings)
  settings = settings or {}
  if not settings.animation then
    local anim, scale = detect_overlay(lab_name)
    settings.animation = anim
    if not settings.scale then
      settings.scale = scale
    end
  end
  PrototypeLabRegistry.registered_labs[lab_name] = settings
end

return PrototypeLabRegistry
