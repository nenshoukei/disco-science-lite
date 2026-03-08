--- @class RemoteInterface
local RemoteInterface = {
  --- @type RemoteInterfaceFunctions
  functions = {},
}

--- @type LabRegistry|nil
local lab_registry = nil
--- @type ColorRegistry|nil
local color_registry = nil

--- @type {fname: string, args: any[]}[]
local pending_calls = {}

--- @param ds_storage DiscoScienceStorage
function RemoteInterface.bind_storage(ds_storage)
  lab_registry = ds_storage.lab_registry
  color_registry = ds_storage.color_registry
  for i = 1, #pending_calls do
    local call = pending_calls[i]
    RemoteInterface.functions[call.fname](table.unpack(call.args))
  end
  pending_calls = {}
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
  assert(type(lab_name) == "string" and lab_name ~= "", "DiscoScience.registerLab: lab_name must be a non-empty string")
  assert(type(settings) == "table", "DiscoScience.registerLab: settings must be a table")
  assert(settings.animation == nil or (type(settings.animation) == "string" and settings.animation ~= ""),
    "DiscoScience.registerLab: settings.animation must be a non-empty string")
  assert(settings.scale == nil or (type(settings.scale) == "number" and settings.scale > 0),
    "DiscoScience.registerLab: settings.scale must be a positive number")
  if not lab_registry then
    pending_calls[#pending_calls + 1] = { fname = "registerLab", args = { lab_name, settings } }
    return
  end
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
  assert(type(lab_name) == "string" and lab_name ~= "", "DiscoScience.setLabScale: lab_name must be a non-empty string")
  assert(type(scale) == "number" and scale > 0, "DiscoScience.setLabScale: scale must be a positive number")
  if not lab_registry then
    pending_calls[#pending_calls + 1] = { fname = "setLabScale", args = { lab_name, scale } }
    return
  end
  lab_registry:set_scale(lab_name, scale)
end

--- Set color for an ingredient (science pack)
---
--- @param name string Name of ItemPrototype of the ingredient
--- @param color Color Color for the ingredient.
function RemoteInterfaceFunctions.setIngredientColor(name, color)
  assert(type(name) == "string" and name ~= "", "DiscoScience.setIngredientColor: name must be a non-empty string")
  assert(type(color) == "table" and (
    (type(color[1]) == "number" and type(color[2]) == "number" and type(color[3]) == "number") or
    (type(color.r) == "number" and type(color.g) == "number" and type(color.b) == "number")
  ), "DiscoScience.setIngredientColor: color must be a Color table")
  if not color_registry then
    pending_calls[#pending_calls + 1] = { fname = "setIngredientColor", args = { name, color } }
    return
  end
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
