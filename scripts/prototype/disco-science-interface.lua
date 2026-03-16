local Utils = require("scripts.shared.utils")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

if _G.DiscoScience then
  return _G.DiscoScience
end

--- @type DiscoScience.Interface
local DiscoScienceInterface = {}
_G.DiscoScience = DiscoScienceInterface

function DiscoScienceInterface.prepareLab(lab, settings)
  settings = settings or {}
  assert(type(lab) == "table" and lab.type == "lab", "DiscoScience.prepareLab: lab must be a LabPrototype table")
  assert(type(lab.name) == "string" and lab.name ~= "", "DiscoScience.prepareLab: lab.name must be a non-empty string")
  assert(type(settings) == "table", "DiscoScience.prepareLab: settings must be a table")
  assert(settings.animation == nil or (type(settings.animation) == "string" and settings.animation ~= ""),
    "DiscoScience.prepareLab: settings.animation must be a non-empty string")
  assert(settings.scale == nil or (type(settings.scale) == "number" and settings.scale > 0),
    "DiscoScience.prepareLab: settings.scale must be a positive number")

  PrototypeLabRegistry.register(lab.name, {
    animation = settings.animation,
    scale = settings.scale,
  })
end

function DiscoScienceInterface.setIngredientColor(item_name, color)
  assert(type(item_name) == "string" and item_name ~= "",
    "DiscoScience.setIngredientColor: item_name must be a non-empty string")
  assert(type(color) == "table" and (
    (type(color[1]) == "number" and type(color[2]) == "number" and type(color[3]) == "number") or
    (type(color.r) == "number" and type(color.g) == "number" and type(color.b) == "number")
  ), "DiscoScience.setIngredientColor: color must be a Color table")

  PrototypeColorRegistry.set(item_name, Utils.color_tuple(color))
end

function DiscoScienceInterface.getIngredientColor(item_name)
  assert(type(item_name) == "string" and item_name ~= "",
    "DiscoScience.getIngredientColor: item_name must be a non-empty string")

  return PrototypeColorRegistry.get(item_name)
end

return DiscoScienceInterface
