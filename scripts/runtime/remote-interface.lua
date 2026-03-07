--- @class RemoteInterface
local RemoteInterface = {
  --- @type RemoteInterfaceFunctions
  functions = {},
}

--- @type LabOverlayRenderer|nil
local renderer = nil
--- @type ColorRegistry|nil
local color_registry = nil

--- @param ds_storage DiscoScienceStorage
function RemoteInterface.bind_storage(ds_storage)
  renderer = ds_storage.renderer
  color_registry = renderer.color_registry
end

--- @class RemoteInterfaceFunctions
local RemoteInterfaceFunctions = RemoteInterface.functions

--- Add a new target lab type.
---
--- @param lab_name string LabPrototype name.
--- @param animation string AnimationPrototype name for an overlay.
--- @param scale integer? Scale of the lab. (Default scale is `1`)
function RemoteInterfaceFunctions.addTargetLab(lab_name, animation, scale)
  if renderer then
    renderer:add_target_lab(lab_name, {
      animation = animation,
      scale = scale or 1,
    })
  end
end

--- Set scale of the target lab.
---
--- If the given lab is not a target, it will registers the lab as a target with the default overlay.
---
--- @param lab_name string LabPrototype name.
--- @param scale integer Scale of the lab. (Default scale is `1`)
function RemoteInterfaceFunctions.setLabScale(lab_name, scale)
  if renderer then
    renderer:set_lab_scale(lab_name, scale)
  end
end

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
function RemoteInterfaceFunctions.getIngredientColor(name)
  if color_registry then
    return color_registry:get_ingredient_color(name)
  end
end

return RemoteInterface
