local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

if _G.DiscoScience then
  return _G.DiscoScience
end

--- @type DiscoScience.Interface
local DiscoScienceInterface = {
  isLite = true,
}
_G.DiscoScience = DiscoScienceInterface

function DiscoScienceInterface.excludeLab(lab)
  local lab_name = type(lab) == "string" and lab or (type(lab) == "table" and lab.name)
  assert(type(lab_name) == "string" and lab_name ~= "",
    "DiscoScience.excludeLab: lab must be a LabPrototype table or a non-empty string")

  PrototypeLabRegistry.exclude(lab_name)
end

function DiscoScienceInterface.prepareLab(lab, settings)
  settings = settings or {}
  assert(type(lab) == "table" and lab.type == "lab", "DiscoScience.prepareLab: lab must be a LabPrototype table")
  assert(type(lab.name) == "string" and lab.name ~= "", "DiscoScience.prepareLab: lab.name must be a non-empty string")
  assert(type(settings) == "table", "DiscoScience.prepareLab: settings must be a table")
  assert(settings.animation == nil or (type(settings.animation) == "string" and settings.animation ~= ""),
    "DiscoScience.prepareLab: settings.animation must be a non-empty string")

  PrototypeLabRegistry.register(lab.name, {
    animation = settings.animation,
  })
end

return DiscoScienceInterface
