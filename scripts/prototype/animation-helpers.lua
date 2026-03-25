local table_merge = require("scripts.shared.utils").table_merge

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
local function copy_geometric_properties(source)
  local result = {}
  for i = 1, #GEOMETRIC_PROPERTIES do
    local prop = GEOMETRIC_PROPERTIES[i]
    result[prop] = source[prop]
  end
  return result
end

-- ---------------------------------------------------------------------------
-- OnAnimationModifier
-- ---------------------------------------------------------------------------

--- A modifier object for lab.on_animation, providing DSL-style methods
--- for layer manipulation. Created internally by `AnimationHelpers.modify_on_animation`.
---
--- @class OnAnimationModifier
--- @field animation data.Animation
local OnAnimationModifier = {}
OnAnimationModifier.__index = OnAnimationModifier

--- @param animation data.Animation
--- @return OnAnimationModifier
function OnAnimationModifier.new(animation)
  return setmetatable({ animation = animation }, OnAnimationModifier)
end

--- Search for a layer from `animation.layers` whose `filename` matches the given filename.
--- Also scans all filenames in `filenames` and `stripes` recursively.
---
--- The first matched layer is returned. If no matches, returns `nil`.
---
--- @param target_filename string filename to search
--- @return data.Animation|nil found_layer
--- @return integer|nil found_layer_index
function OnAnimationModifier:get_layer(target_filename)
  local layers = self.animation.layers
  if not layers then return nil, nil end

  for i = 1, #layers do
    local layer = layers[i]

    local filename = layer.filename
    if filename == target_filename then
      return layer, i
    end

    local filenames = layer.filenames
    if filenames then
      for j = 1, #filenames do
        if filenames[j] == target_filename then
          return layer, i
        end
      end
    end

    local stripes = layer.stripes
    if stripes then
      for j = 1, #stripes do
        if stripes[j].filename == target_filename then
          return layer, i
        end
      end
    end
  end

  return nil, nil
end

--- Remove a layer from `animation.layers` whose `filename` matches the given filename.
--- Also scans all filenames in `filenames` and `stripes` recursively.
---
--- Only the first matched layer is removed and returned. If no matches, returns `nil`.
---
--- Does nothing if `animation.layers` is nil.
---
--- @param target_filename string filename to remove
--- @return data.Animation|nil removed_layer
function OnAnimationModifier:remove_layer(target_filename)
  local layers = self.animation.layers
  if not layers then return nil end

  local layer, index = self:get_layer(target_filename)
  if layer then
    table.remove(layers, index)
  end
  return layer
end

--- Replace `old_filename` with `new_filename` in an animation's `filename`, `filenames`,
--- `stripes`, and recursively in all entries of `layers`.
---
--- @param old_filename string
--- @param new_filename string
function OnAnimationModifier:replace_filename(old_filename, new_filename)
  local function replace(animation)
    if animation.filename == old_filename then
      animation.filename = new_filename
    end

    local filenames = animation.filenames
    if filenames then
      for i = 1, #filenames do
        if filenames[i] == old_filename then
          filenames[i] = new_filename
        end
      end
    end

    local stripes = animation.stripes
    if stripes then
      for i = 1, #stripes do
        if stripes[i].filename == old_filename then
          stripes[i].filename = new_filename
        end
      end
    end

    local layers = animation.layers
    if layers then
      for i = 1, #layers do
        replace(layers[i])
      end
    end
  end

  replace(self.animation)
end

--- Insert a mask layer immediately after the layer matching `target_filename` (or `target_filenames`)
--- in `animation.layers`. The mask layer inherits geometric properties from the target layer,
--- with optional overrides from `override_props`. Does nothing if the target is not found
--- or if `animation.layers` is nil.
---
--- When `target_filename` is a string array, it matches layers whose `filenames` field equals
--- that array (joined with "|"). When `mask_filename` is a string array, the inserted layer
--- uses `filenames` instead of `filename`.
---
--- @param target_filename string|string[]
--- @param mask_filename string|string[]
--- @param override_props data.Animation?
function OnAnimationModifier:insert_mask_layer(target_filename, mask_filename, override_props)
  local layers = self.animation.layers
  if not layers then return end

  local target_key --- @type string
  if type(target_filename) == "table" then
    target_key = table.concat(target_filename --[[@as string[] ]], "|")
  else
    target_key = target_filename --[[@as string]]
  end

  local insertion_index = nil --- @type integer?
  local source_layer = nil    --- @type data.Animation?

  for i = 1, #layers do
    local layer = layers[i]
    local layer_key --- @type string?
    if layer.filename then
      layer_key = layer.filename
    elseif layer.filenames then
      layer_key = table.concat(layer.filenames, "|")
    end

    if layer_key == target_key then
      insertion_index = i + 1
      source_layer = layer
      break
    end
  end

  if not insertion_index then return end --- @cast source_layer -nil

  local new_layer = copy_geometric_properties(source_layer)

  if type(mask_filename) == "table" then
    new_layer.filenames = mask_filename --[[@as string[] ]]
    new_layer.lines_per_file = source_layer.lines_per_file
  else
    new_layer.filename = mask_filename --[[@as string]]
  end

  if override_props then
    for k, v in pairs(override_props) do
      new_layer[k] = v
    end
  end

  table.insert(layers, insertion_index, new_layer)
end

--- Freeze all layers in `animation.layers` to a single frame.
---
--- Sets `frame_sequence = {frame_index}` and clears `repeat_count` on every layer.
--- Does nothing if `animation.layers` is nil.
---
--- @param frame_index integer? 1-based frame index to freeze at. (Default: `1`)
function OnAnimationModifier:freeze_animation(frame_index)
  local layers = self.animation.layers
  if not layers then return end

  frame_index = frame_index or 1
  for i = 1, #layers do
    layers[i].frame_sequence = { frame_index }
    layers[i].repeat_count = nil
  end
end

--- Apply the same modifications as for the vanilla lab.
---
--- @param filenames { lab: string?, lab_light: string? }?
function OnAnimationModifier:apply_lab_modifications(filenames)
  local lab_filename = filenames and filenames.lab or "__base__/graphics/entity/lab/lab.png"
  local lab_light_filename = filenames and filenames.lab_light or "__base__/graphics/entity/lab/lab-light.png"

  self:remove_layer(lab_light_filename)

  --- Replace lab.png with a darkend mask image.
  self:insert_mask_layer(
    lab_filename,
    "__disco-science-lite__/graphics/factorio/lab-mask.png" --[[$GRAPHICS_DIR .. "factorio/lab-mask.png"]],
    { frame_count = 1, line_length = 1 }
  )
  self:remove_layer(lab_filename)

  --- Support Factorio HD Age
  if mods["factorio_hd_age_base_game_production"] then
    self:remove_layer("__factorio_hd_age_base_game_production__/data/base/graphics/entity/lab/lab-light.png")

    -- We cannot create an HD mask image for HD Age because it requires GPLv3 license, so keep lab.png as-is.
    -- Without mask, the lab will get brighter than the original, which does not matter so much.
  end

  -- Freeze entity animation at frame 1 (no light, no color in the overlay area).
  -- The overlay animation still plays normally to provide the disco color effect.
  self:freeze_animation()
end

--- Apply the same modifications as for the vanilla biolab.
function OnAnimationModifier:apply_biolab_modifications()
  self:remove_layer("__space-age__/graphics/entity/biolab/biolab-lights.png")

  --- Support Factorio HD Age
  if mods["factorio_hd_age_space_age_production"] then
    self:remove_layer("__factorio_hd_age_space_age_production__/data/space-age/graphics/entity/biolab/biolab-lights.png")
  end
end

-- ---------------------------------------------------------------------------
-- AnimationHelpers
-- ---------------------------------------------------------------------------

--- @class AnimationHelpers
local AnimationHelpers = {}

AnimationHelpers.copy_geometric_properties = copy_geometric_properties

--- @class AnimationOverrideProps : data.Animation
--- @field name string

--- Convert an Animation to an AnimationPrototype with override properties applied.
---
--- @param animation data.Animation
--- @param override_props AnimationOverrideProps?
--- @return data.AnimationPrototype
function AnimationHelpers.convert_to_animation_prototype(animation, override_props)
  local animation_proto = table_merge(animation, override_props or {}) --[[@as data.AnimationPrototype]]
  animation_proto.type = "animation"
  return animation_proto
end

--- Convert an AnimationPrototype to an Animation with override properties applied.
---
--- @param animation_proto data.AnimationPrototype
--- @param override_props data.Animation?
--- @return data.Animation
function AnimationHelpers.convert_to_animation(animation_proto, override_props)
  local animation = table_merge(animation_proto, override_props or {})
  animation.type = nil
  animation.name = nil
  return animation --[[@as data.Animation]]
end

--- Use OnAnimationModifier for modifying lab.on_animation.
---
--- Callback is called with an OnAnimationModifier wrapping the lab's on_animation,
--- so helper functions are callable like `on_animation:remove_layer("target-file-name.png")`.
---
--- If target lab is not defined or lab.on_animation is nil, callback is not called.
---
--- @param lab_name string
--- @param callback fun(on_animation: OnAnimationModifier, lab: data.LabPrototype)
function AnimationHelpers.modify_on_animation(lab_name, callback)
  local lab = data.raw["lab"][lab_name]
  if not lab then
    log('Disco Science Lite: Target lab prototype "' .. lab_name .. '" is not defined in data.raw')
    return
  end

  local on_animation = lab.on_animation
  if not on_animation then
    log("Disco Science Lite: Target lab has no on_animation")
    return
  end

  local modifier = OnAnimationModifier.new(on_animation)
  callback(modifier, lab)
end

--- Exposed for testing only.
AnimationHelpers.OnAnimationModifier = OnAnimationModifier

return AnimationHelpers
