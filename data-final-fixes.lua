local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")

local all_mods = require("scripts.prototype.mods._all")
for i = 1, #all_mods do
  local mod = all_mods[i]
  if mod.on_data_final_fixes then mod.on_data_final_fixes() end
end

PrototypeLabRegistry.validate_registrations()

-- Add the lab creation trigger to all registered lab prototypes.
LabPrototypeModifier.modify_registered_labs(data.raw["lab"])
