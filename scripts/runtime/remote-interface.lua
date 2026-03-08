--- @class RemoteInterface
local RemoteInterface = {
  --- @type RemoteInterfaceFunctions
  functions = {},
}

--- @type LabRegistry|nil
local lab_registry = nil
--- @type ColorRegistry|nil
local color_registry = nil

--- @param ds_storage DiscoScienceStorage
function RemoteInterface.bind_storage(ds_storage)
  lab_registry = ds_storage.lab_registry
  color_registry = ds_storage.color_registry
end

--- @class RemoteInterfaceFunctions
local RemoteInterfaceFunctions = RemoteInterface.functions

--- Register a lab type for Disco-Science colorization.
---
--- `settings` can be used for specifying the rendering settings for the lab overlay.
--- If not passed, the default settings are used. (See [LabOverlaySettings](lua://LabOverlaySettings))
---
--- This overrides the existing settings with the same name registered by DiscoScience.prepareLab() at prototype stage.
---
--- @param lab_name string LabPrototype name.
--- @param settings LabOverlaySettings? Settings for the lab overlay.
function RemoteInterfaceFunctions.registerLab(lab_name, settings)
  if not lab_registry then return end
  assert(type(lab_name) == "string" and lab_name ~= "", "DiscoScience.registerLab: lab_name must be a non-empty string")
  assert(type(settings) == "table", "DiscoScience.registerLab: settings must be a table")
  assert(settings.animation == nil or (type(settings.animation) == "string" and settings.animation ~= ""),
    "DiscoScience.registerLab: settings.animation must be a non-empty string")
  assert(settings.scale == nil or (type(settings.scale) == "number" and settings.scale > 0),
    "DiscoScience.registerLab: settings.scale must be a positive number")
  lab_registry:register(lab_name, {
    animation = settings.animation,
    scale = settings.scale,
  })
end

--- Set scale of a lab overlay.
---
--- If the given lab has not been registered yet, it will be registered with the default lab overlay settings.
--- (See [LabOverlaySettings](lua://LabOverlaySettings))
---
--- @param lab_name string LabPrototype name.
--- @param scale integer Scale of the lab. (Default scale is `1`)
function RemoteInterfaceFunctions.setLabScale(lab_name, scale)
  if not lab_registry then return end
  assert(type(lab_name) == "string" and lab_name ~= "", "DiscoScience.setLabScale: lab_name must be a non-empty string")
  assert(type(scale) == "number" and scale > 0, "DiscoScience.setLabScale: scale must be a positive number")
  lab_registry:set_scale(lab_name, scale)
end

--- Set color for an ingredient (science pack)
---
--- @param name string Name of ItemPrototype of the ingredient
--- @param color Color Color for the ingredient.
function RemoteInterfaceFunctions.setIngredientColor(name, color)
  if not color_registry then return end
  assert(type(name) == "string" and name ~= "", "DiscoScience.setIngredientColor: name must be a non-empty string")
  assert(type(color) == "table" and (
    (type(color[1]) == "number" and type(color[2]) == "number" and type(color[3]) == "number") or
    (type(color.r) == "number" and type(color.g) == "number" and type(color.b) == "number")
  ), "DiscoScience.setIngredientColor: color must be a Color table")
  color_registry:set_ingredient_color(name, color)
end

--- Get color for an ingredient (science pack)
---
--- @param name string Name of ItemPrototype of the ingredient
--- @return Color|nil color Color for the ingredient, or `nil` for non-registered ingredients.
function RemoteInterfaceFunctions.getIngredientColor(name)
  if not color_registry then return end
  assert(type(name) == "string" and name ~= "", "DiscoScience.getIngredientColor: name must be a non-empty string")
  return color_registry:get_ingredient_color(name)
end

return RemoteInterface
