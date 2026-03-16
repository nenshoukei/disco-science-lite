local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

if _G.DiscoScienceLabPrototypeModifier then
  return _G.DiscoScienceLabPrototypeModifier
end

local LabPrototypeModifier = {
  --- Animation filenames to be removed from on_animation.layers. Value is always `true`.
  --- @type table<string, boolean>
  remove_layer_filenames = {},

  --- Animation filenames to be replaced to new filenames.
  --- @type table<string, string>
  replace_filenames = {},

  --- Modified lab prototypes
  --- @type table<data.LabPrototype, boolean>
  modified_labs = {},
}
_G.DiscoScienceLabPrototypeModifier = LabPrototypeModifier

--- Just for testing.
function LabPrototypeModifier.reset()
  LabPrototypeModifier.remove_layer_filenames = {}
  LabPrototypeModifier.replace_filenames = {}
  LabPrototypeModifier.modified_labs = {}
end

--- Apply filename modifications to an Animation or a SpriteSource.
---
--- @param animation data.Animation|data.SpriteSource
local function apply_filename_modifications(animation)
  local replace_filenames = LabPrototypeModifier.replace_filenames

  local new_fn = animation.filename and replace_filenames[animation.filename]
  if new_fn then
    animation.filename = new_fn
  end

  local filenames = animation.filenames
  if filenames then --- @cast filenames -nil
    for i, filename in ipairs(filenames) do
      local new_fn_ = replace_filenames[filename]
      if new_fn_ then
        filenames[i] = new_fn_
      end
    end
  end

  local layers = animation.layers
  if layers then
    local remove_layer_filenames = LabPrototypeModifier.remove_layer_filenames
    for i = #layers, 1, -1 do
      local layer = layers[i]
      if layer.filename and remove_layer_filenames[layer.filename] then
        table.remove(layers, i)
      else
        apply_filename_modifications(layer)
      end
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

--- Set a filename to be removed from `on_animation` layers.
---
--- @param filename string
function LabPrototypeModifier.set_filename_removal(filename)
  LabPrototypeModifier.remove_layer_filenames[filename] = true
end

--- Modify all lab prototypes registered by `DiscoScienceInterface.prepareLab()`,
--- including Factorio's basic lab prototypes.
---
--- If `fallback_overlay_enabled` setting is `true`, all lab prototypes without registration
--- will also be modified for colorization.
---
--- @param lab_prototypes { [string]: data.LabPrototype }
function LabPrototypeModifier.modify_registered_labs(lab_prototypes)
  local registered_labs = PrototypeLabRegistry.registered_labs
  local fallback_enabled = settings.startup[ "mks-dsl-fallback-overlay-enabled" --[[$FALLBACK_OVERLAY_ENABLED_NAME]] ]
    .value
  for name, proto in pairs(lab_prototypes) do
    if fallback_enabled or registered_labs[name] then
      LabPrototypeModifier.modify_lab(proto)
    end
  end
end

--- Modify LabPrototype for this mod.
---
--- * Applies the filename replacement on `on_animation` if exists.
--- * Adds the lab creation trigger.
---
--- If the prototype is already modified, it does nothing.
---
--- @param lab data.LabPrototype
function LabPrototypeModifier.modify_lab(lab)
  if LabPrototypeModifier.modified_labs[lab] then return end

  if lab.on_animation then
    apply_filename_modifications(lab.on_animation)
  end

  add_lab_trigger(lab)

  LabPrototypeModifier.modified_labs[lab] = true
end

return LabPrototypeModifier
