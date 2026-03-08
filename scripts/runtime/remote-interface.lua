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

--- Add a new lab registration.
---
--- @param lab_name string LabPrototype name.
--- @param animation string AnimationPrototype name for an overlay.
--- @param scale integer? Scale of the lab. (Default scale is `1`)
function RemoteInterfaceFunctions.addTargetLab(lab_name, animation, scale)
  if not lab_registry then return end
  assert(type(lab_name) == "string" and lab_name ~= "", "DiscoScience.addTargetLab: lab_name must be a non-empty string")
  assert(type(animation) == "string" and animation ~= "",
    "DiscoScience.addTargetLab: animation must be a non-empty string")
  assert(scale == nil or (type(scale) == "number" and scale > 0),
    "DiscoScience.addTargetLab: scale must be a positive number")
  lab_registry:add(lab_name, {
    animation = animation,
    scale = scale or 1,
  })
end

--- Set scale of a lab registration.
---
--- If the given lab has no registration yet, it will be registered with the default overlay.
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
