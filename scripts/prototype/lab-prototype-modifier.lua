local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

if _G.DiscoScienceLabPrototypeModifier then
  return _G.DiscoScienceLabPrototypeModifier
end

--- @class (exact) MaskEntry
--- @field [1] string|string[] mask filename or filenames
--- @field [2] data.Animation? optional property overrides for the inserted layer

local LabPrototypeModifier = {
  --- Animation filenames to be removed from on_animation.layers. Value is always `true`.
  --- @type table<string, boolean>
  remove_layer_filenames = {},

  --- Animation filenames to be replaced to new filenames.
  --- @type table<string, string>
  replace_filenames = {},

  --- Mask entries to insert after the layer with the given filename or filenames.
  --- The key is `filename` for single-file layers, or `table.concat(filenames, "|")` for multi-file layers.
  --- The mask layer inherits geometric properties from the target layer, with optional overrides.
  --- @type table<string, MaskEntry>
  insert_mask_filenames = {},

  --- Animation freeze triggers: when a layer with the given filename is found,
  --- all layers in the same layers array are frozen to the specified 1-based frame index.
  --- @type table<string, integer>
  animation_freeze_triggers = {},

  --- Modified lab prototypes
  --- @type table<data.LabPrototype, boolean>
  modified_labs = {},
}
_G.DiscoScienceLabPrototypeModifier = LabPrototypeModifier

--- Just for testing.
function LabPrototypeModifier.reset()
  LabPrototypeModifier.remove_layer_filenames = {}
  LabPrototypeModifier.replace_filenames = {}
  LabPrototypeModifier.insert_mask_filenames = {}
  LabPrototypeModifier.animation_freeze_triggers = {}
  LabPrototypeModifier.modified_labs = {}
end

--- Apply modifications to an Animation or a SpriteSource.
---
--- @param animation data.Animation|data.SpriteSource
local function modify_animation(animation)
  local replace_filenames = LabPrototypeModifier.replace_filenames

  local new_filename = animation.filename and replace_filenames[animation.filename]
  if new_filename then
    animation.filename = new_filename
  end

  local a_filenames = animation.filenames
  if a_filenames then
    for i = 1, #a_filenames do
      new_filename = replace_filenames[a_filenames[i]]
      if new_filename then
        a_filenames[i] = new_filename
      end
    end
  end

  local layers = animation.layers
  if not layers then return end

  local remove_set = LabPrototypeModifier.remove_layer_filenames
  local mask_set = LabPrototypeModifier.insert_mask_filenames
  local freeze_triggers = LabPrototypeModifier.animation_freeze_triggers

  --- @type [integer, data.Animation][]
  local insertions = {}
  local insertions_count = 0
  local freeze_frame = nil
  local layers_count = 0

  for i = 1, #layers do
    local layer = layers[i]
    local filename = layer.filename
    local filenames = layer.filenames

    local should_remove = filename and remove_set[filename]
    if not should_remove and filenames then
      for j = 1, #filenames do
        if remove_set[filenames[j]] then
          should_remove = true
          break
        end
      end
    end
    if should_remove then
      goto next_layer
    end

    modify_animation(layer)
    layers_count = layers_count + 1
    layers[layers_count] = layer

    local mask_entry --- @type MaskEntry
    if filename then
      mask_entry = mask_set[filename]
    elseif filenames then
      mask_entry = mask_set[table.concat(filenames, "|")]
    end
    if mask_entry then
      local mask_filename = mask_entry[1]
      local mask_overrides = mask_entry[2]

      --- @type data.Animation
      local new_layer = {
        width = layer.width,
        height = layer.height,
        frame_count = layer.frame_count,
        line_length = layer.line_length,
        scale = layer.scale,
        shift = layer.shift,
        animation_speed = layer.animation_speed,
      }

      if type(mask_filename) == "table" then
        new_layer.filenames = mask_filename --[[@as string[] ]]
        new_layer.lines_per_file = layer.lines_per_file
      else
        new_layer.filename = mask_filename --[[@as string]]
      end

      if mask_overrides then
        for k, v in pairs(mask_overrides) do
          new_layer[k] = v
        end
      end

      insertions_count = insertions_count + 1
      insertions[insertions_count] = { layers_count + 1, new_layer }
    end

    if not freeze_frame and filename then
      freeze_frame = freeze_triggers[filename]
    end

    ::next_layer::
  end

  -- Clear removed tail
  for i = layers_count + 1, #layers do
    layers[i] = nil
  end

  -- Apply mask insertions (backward to preserve indices)
  for j = insertions_count, 1, -1 do
    table.insert(layers, insertions[j][1], insertions[j][2])
  end

  -- Apply freeze to all layers (including inserted mask layers)
  if freeze_frame then
    for i = 1, #layers do
      layers[i].frame_sequence = { freeze_frame }
      layers[i].repeat_count = nil
    end
  end
end

--- Add the lab creation trigger to the lab prototype.
---
--- @param lab data.LabPrototype
local function add_lab_trigger(lab)
  --- @type data.DirectTriggerItem
  local trigger = {
    type = "direct",
    action_delivery = {
      type = "instant",
      source_effects = {
        type = "script",
        effect_id = "ds-create-lab" --[[$LAB_CREATED_EFFECT_ID]],
      },
    },
  }

  if lab.created_effect then
    if lab.created_effect.type then
      -- Change the TriggerItem to array[TriggerItem]
      lab.created_effect = { lab.created_effect --[[@as data.AnyTriggerItem]] }
    end
    lab.created_effect[#lab.created_effect + 1] = trigger
  else
    lab.created_effect = trigger
  end
end

--- Set a filename to be replaced to a new filename in `on_animation`.
---
--- @param old_filename string
--- @param new_filename string
function LabPrototypeModifier.set_filename_replacement(old_filename, new_filename)
  LabPrototypeModifier.replace_filenames[old_filename] = new_filename
end

--- Set filenames to be removed from `on_animation` layers.
---
--- @param ... string
function LabPrototypeModifier.set_layer_removal(...)
  local remove_layer_filenames = LabPrototypeModifier.remove_layer_filenames
  for i = 1, select("#", ...) do
    remove_layer_filenames[select(i, ...)] = true
  end
end

--- Set a mask layer to be inserted on top of the layer with the specified filename(s) in `on_animation`.
--- The mask layer inherits width, height, frame_count, line_length, scale, shift, and animation_speed
--- from the target layer, with optional overrides from `override_props`.
---
--- When `target_filename` is a string array, it matches layers whose `filenames` field equals that array.
--- When `mask_filename` is a string array, the inserted layer uses `filenames` instead of `filename`.
---
--- @param target_filename string|string[]
--- @param mask_filename string|string[]
--- @param override_props data.Animation?
function LabPrototypeModifier.set_layer_mask(target_filename, mask_filename, override_props)
  local key
  if type(target_filename) == "table" then
    key = table.concat(target_filename --[[@as string[] ]], "|")
  else
    key = target_filename --[[@as string]]
  end
  LabPrototypeModifier.insert_mask_filenames[key] = { mask_filename, override_props }
end

--- Freeze all layers in the animation containing the trigger layer to a single frame.
--- When a layer with `trigger_filename` is found in a layers array, sets
--- frame_sequence = {frame_index} and repeat_count = nil on every layer in that array.
---
--- @param trigger_filename string
--- @param frame_index integer 1-based frame index to freeze at
function LabPrototypeModifier.set_animation_freeze(trigger_filename, frame_index)
  LabPrototypeModifier.animation_freeze_triggers[trigger_filename] = frame_index
end

--- Modify all lab prototypes registered by `DiscoScienceInterface.prepareLab()`,
--- including Factorio's basic lab prototypes.
---
--- If `fallback_overlay_enabled` setting is `true`, all lab prototypes without registration and exclusion
--- will also be modified for colorization.
---
--- @param lab_prototypes { [string]: data.LabPrototype }
function LabPrototypeModifier.modify_registered_labs(lab_prototypes)
  local registered_labs = PrototypeLabRegistry.registered_labs
  local excluded_labs = PrototypeLabRegistry.excluded_labs
  local fallback_enabled = settings.startup[ "mks-dsl-fallback-overlay-enabled" --[[$FALLBACK_OVERLAY_ENABLED_NAME]] ]
    .value
  for name, proto in pairs(lab_prototypes) do
    if not excluded_labs[name] and (fallback_enabled or registered_labs[name]) then
      LabPrototypeModifier.modify_lab(proto)
    end
  end
end

--- Modify LabPrototype for this mod.
---
--- * Applies the modifications on `on_animation` if exists.
--- * Adds the lab creation trigger.
---
--- If the prototype is already modified, it does nothing.
---
--- @param lab data.LabPrototype
function LabPrototypeModifier.modify_lab(lab)
  if LabPrototypeModifier.modified_labs[lab] then return end

  if lab.on_animation then
    modify_animation(lab.on_animation)
  end

  add_lab_trigger(lab)

  LabPrototypeModifier.modified_labs[lab] = true
end

return LabPrototypeModifier
