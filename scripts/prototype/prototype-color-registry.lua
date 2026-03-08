local Utils = require("scripts.shared.utils")
local config_ingredient_colors = require("scripts.shared.config.ingredient-colors")

--- Registry for ingredient colors at prototype stage.
local PrototypeColorRegistry = {
  --- Registered ingredient colors. Key is ingredient's ItemPrototype name.
  ---
  --- This table is stored as mod-data prototype for runtime stage.
  --- @type table<string, ColorTuple>
  registered_colors = Utils.table_deep_copy(config_ingredient_colors),
}

--- Resets the registry. Just for testing.
function PrototypeColorRegistry.reset()
  PrototypeColorRegistry.registered_colors = Utils.table_deep_copy(config_ingredient_colors)
end

--- Get color for an ingredient (science pack).
---
--- @param name string Name of ItemPrototype of the ingredient
--- @return Color|nil color Color for the ingredient, or `nil` for non-registered ingredients.
function PrototypeColorRegistry.get(name)
  local color = PrototypeColorRegistry.registered_colors[name]
  return color and Utils.color_struct(color)
end

--- Set color for an ingredient (science pack).
---
--- This overwrites the existing color with the same name.
---
--- @param name string Name of ItemPrototype of the ingredient
--- @param color ColorTuple Color for the ingredient.
function PrototypeColorRegistry.set(name, color)
  PrototypeColorRegistry.registered_colors[name] = color
end

return PrototypeColorRegistry
