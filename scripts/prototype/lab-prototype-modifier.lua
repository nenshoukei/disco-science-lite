local consts = require("scripts.shared.consts")

local LabPrototypeModifier = {}

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
        effect_id = consts.LAB_CREATED_EFFECT_ID,
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

--- Modify all lab prototypes to support colorization.
---
--- @param lab_prototypes { [string]: data.LabPrototype }
function LabPrototypeModifier.modify_target_labs(lab_prototypes)
  for _, proto in pairs(lab_prototypes) do
    LabPrototypeModifier.modify_lab(proto)
  end
end

--- Modify LabPrototype for this mod (for labs with a registered overlay sprite).
---
--- Disables the default working animation so the overlay can replace it,
--- then adds the lab creation trigger.
---
--- @param lab data.LabPrototype
function LabPrototypeModifier.modify_lab(lab)
  -- Disable the default working animation (the dedicated overlay replaces it)
  lab.on_animation = lab.off_animation

  add_lab_trigger(lab)
end

return LabPrototypeModifier
