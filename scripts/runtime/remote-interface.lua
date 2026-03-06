--- @class RemoteInterface
local RemoteInterface = {
  --- @type RemoteInterfaceFunctions
  functions = {},
}

--- @type ColorRegistry|nil
local color_registry = nil

--- @param ds_storage DiscoScienceStorage
function RemoteInterface.bind_storage(ds_storage)
  color_registry = ds_storage.color_registry
end

--- @class RemoteInterfaceFunctions
local RemoteInterfaceFunctions = RemoteInterface.functions

--- Set color for an ingredient (science pack)
---
--- @param name string Name of ItemPrototype of the ingredient
--- @param color Color Color for the ingredient.
function RemoteInterfaceFunctions.setIngredientColor(name, color)
  if color_registry then
    color_registry:set_ingredient_color(name, color)
  end
end

--- Get color for an ingredient (science pack)
---
--- @param name string Name of ItemPrototype of the ingredient
--- @return Color|nil color Color for the ingredient, or `nil` for non-registered ingredients.
function RemoteInterfaceFunctions.get_ingredient_color(name)
  if color_registry then
    return color_registry:get_ingredient_color(name)
  end
end

return RemoteInterface
