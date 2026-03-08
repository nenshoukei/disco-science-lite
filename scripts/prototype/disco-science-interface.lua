local Utils = require("scripts.shared.utils")
local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

--- Public interface `_G.DiscoScience` for other mods on prototype stage.
---
--- Compatible with the original DiscoScience mod interface.
---
--- @class DiscoScienceInterface
local DiscoScienceInterface = {}

--- Prepare a lab prototype for Disco-Science colorization.
---
--- `settings` can be used for specifying the rendering settings for the lab overlay.
--- If not passed, the default settings are used. (See [LabOverlaySettings](lua://LabOverlaySettings))
--- These settings can be overridden at runtime by `remote.call()`. See API documents for details.
---
--- @param lab data.LabPrototype LabPrototype to be prepared.
--- @param settings LabOverlaySettings? Settings for the lab overlay.
function DiscoScienceInterface.prepareLab(lab, settings)
  settings = settings or {}
  assert(type(lab) == "table" and lab.type == "lab", "DiscoScience.prepareLab: lab must be a LabPrototype table")
  assert(type(lab.name) == "string" and lab.name ~= "", "DiscoScience.prepareLab: lab.name must be a non-empty string")
  assert(type(settings) == "table", "DiscoScience.prepareLab: settings must be a table")
  assert(settings.animation == nil or (type(settings.animation) == "string" and settings.animation ~= ""),
    "DiscoScience.prepareLab: settings.animation must be a non-empty string")
  assert(settings.scale == nil or (type(settings.scale) == "number" and settings.scale > 0),
    "DiscoScience.prepareLab: settings.scale must be a positive number")

  LabPrototypeModifier.modify_lab(lab)
  PrototypeLabRegistry.register(lab.name, {
    animation = settings.animation,
    scale = settings.scale,
  })
end

--- Set color for an ingredient (science pack) at prototype stage.
---
--- These colors can be overridden at runtime by `remote.call()`. See API documents for details.
---
--- @param name string Name of ItemPrototype of the ingredient
--- @param color Color Color for the ingredient.
function DiscoScienceInterface.setIngredientColor(name, color)
  assert(type(name) == "string" and name ~= "", "DiscoScience.setIngredientColor: name must be a non-empty string")
  assert(type(color) == "table" and (
    (type(color[1]) == "number" and type(color[2]) == "number" and type(color[3]) == "number") or
    (type(color.r) == "number" and type(color.g) == "number" and type(color.b) == "number")
  ), "DiscoScience.setIngredientColor: color must be a Color table")
  PrototypeColorRegistry.set(name, Utils.color_tuple(color))
end

return DiscoScienceInterface
