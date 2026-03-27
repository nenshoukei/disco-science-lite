local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")
local Settings = require("scripts.shared.settings")

if _G.DiscoScienceLabPrototypeModifier then
  return _G.DiscoScienceLabPrototypeModifier
end

local LabPrototypeModifier = {
  --- Modified lab prototypes
  --- @type table<data.LabPrototype, boolean>
  modified_labs = {},
}
_G.DiscoScienceLabPrototypeModifier = LabPrototypeModifier

--- Just for testing.
function LabPrototypeModifier.reset()
  LabPrototypeModifier.modified_labs = {}
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

--- Modify all lab prototypes registered by `DiscoScienceInterface.prepareLab()`,
--- including Factorio's basic lab prototypes.
---
--- If `fallback_overlay_enabled` setting is `true`, all lab prototypes without registration
--- and exclusion will also be modified for colorization.
---
--- @param lab_prototypes { [string]: data.LabPrototype }
function LabPrototypeModifier.modify_registered_labs(lab_prototypes)
  local registered_labs = PrototypeLabRegistry.registered_labs
  local excluded_labs = PrototypeLabRegistry.excluded_labs
  local is_fallback_enabled = Settings.is_fallback_enabled
  for name, proto in pairs(lab_prototypes) do
    if not excluded_labs[name] and (is_fallback_enabled or registered_labs[name]) then
      LabPrototypeModifier.modify_lab(proto)
    end
  end
end

--- Modify LabPrototype for this mod.
---
--- * Adds the lab creation trigger.
--- * Freezes the lab on_animation if it is registered without a custom animation.
---
--- If the prototype is already modified, it does nothing.
---
--- @param lab data.LabPrototype
function LabPrototypeModifier.modify_lab(lab)
  if LabPrototypeModifier.modified_labs[lab] then return end

  add_lab_trigger(lab)

  -- When registered without a custom animation (e.g. via prepareLab without options.animation),
  -- freeze on_animation to match original DiscoScience behavior (lab stays static while overlay animates).
  local registration = PrototypeLabRegistry.registered_labs[lab.name]
  if registration and not registration.animation then
    AnimationHelpers.modify_on_animation(lab.name, function (modifier)
      modifier:freeze_animation()
    end)
  end

  LabPrototypeModifier.modified_labs[lab] = true
end

return LabPrototypeModifier
