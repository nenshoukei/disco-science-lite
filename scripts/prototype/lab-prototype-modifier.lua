local consts = require("scripts.shared.consts")
local config_target_labs = require("scripts.shared.config.target-labs")

local LabPrototypeModifier = {}

--- Modify all target lab prototypes
---
--- @param lab_prototypes { [string]: data.LabPrototype }
function LabPrototypeModifier.modify_target_labs(lab_prototypes)
  for name in pairs(config_target_labs) do
    local proto = lab_prototypes[name]
    if proto then
      LabPrototypeModifier.modify_lab(proto)
    end
  end
end

--- Modify LabPrototype for this mod
---
--- @param lab data.LabPrototype
function LabPrototypeModifier.modify_lab(lab)
  -- Disable the default blue light working animation
  lab.on_animation = lab.off_animation

  --- Trigger effect for creating a lab entity
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

return LabPrototypeModifier
