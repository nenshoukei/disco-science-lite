local Utils = require("scripts.shared.utils")

if _G.DiscoSciencePrototypeColorRegistry then
  return _G.DiscoSciencePrototypeColorRegistry
end

--- Registry for ingredient colors at prototype stage.
local PrototypeColorRegistry = {
  --- Registered ingredient colors. Key is ingredient's ItemPrototype name.
  ---
  --- This table is stored as mod-data prototype for runtime stage.
  --- @type table<string, ColorTuple>
  registered_colors = {},
}
_G.DiscoSciencePrototypeColorRegistry = PrototypeColorRegistry

--- Resets the registry. Just for testing.
function PrototypeColorRegistry.reset()
  PrototypeColorRegistry.registered_colors = {}
end

--- Get color for an ingredient (science pack).
---
--- @param item_name string Name of ItemPrototype of the ingredient
--- @return Color|nil color Color for the ingredient, or `nil` for non-registered ingredients.
function PrototypeColorRegistry.get(item_name)
  local color = PrototypeColorRegistry.registered_colors[item_name]
  return color and Utils.color_struct(color)
end

--- Set color for an ingredient (science pack).
---
--- This overwrites the existing color with the same name.
---
--- @param item_name string Name of ItemPrototype of the ingredient
--- @param color ColorTuple Color for the ingredient.
function PrototypeColorRegistry.set(item_name, color)
  PrototypeColorRegistry.registered_colors[item_name] = color
end

--- Set colors for ingredients by a table.
---
--- This overwrites the existing colors with the same names.
---
--- @param item_name_to_color table<string, ColorTuple> ItemPrototype name to color table.
function PrototypeColorRegistry.set_by_table(item_name_to_color)
  local registered_colors = PrototypeColorRegistry.registered_colors
  for item_name, color in pairs(item_name_to_color) do
    registered_colors[item_name] = color
  end
end

return PrototypeColorRegistry
