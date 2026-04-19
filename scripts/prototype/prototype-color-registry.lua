local Utils = require("scripts.shared.utils")

if _G.DiscoSciencePrototypeColorRegistry then
  return _G.DiscoSciencePrototypeColorRegistry
end

--- Registry for ingredient colors at prototype stage.
local PrototypeColorRegistry = {
  --- Registered ingredient colors. Key is ingredient's ItemPrototype name.
  ---
  --- This table is stored as mod-data prototype for runtime stage.
  --- @type table<string, ColorTuple[]>
  registered_colors = {},

  --- Registered ingredient color prefixes for fallback lookup.
  ---
  --- When an ingredient color is not found by exact name, each prefix is tried.
  --- If the ingredient name starts with a prefix, the prefix is stripped and the base name is looked up.
  ---
  --- This table is stored as mod-data prototype for runtime stage.
  --- @type string[]
  registered_prefixes = {},

  --- Registered ingredient color suffixes for fallback lookup.
  ---
  --- When an ingredient color is not found by exact name or prefix, each suffix is tried.
  --- If the ingredient name ends with a suffix, the suffix is stripped and the base name is looked up.
  ---
  --- This table is stored as mod-data prototype for runtime stage.
  --- @type string[]
  registered_suffixes = {},
}
_G.DiscoSciencePrototypeColorRegistry = PrototypeColorRegistry

--- Resets the registry. Just for testing.
function PrototypeColorRegistry.reset()
  PrototypeColorRegistry.registered_colors = {}
  PrototypeColorRegistry.registered_prefixes = {}
  PrototypeColorRegistry.registered_suffixes = {}
end

--- Normalize a ColorTuple or ColorTuple[] to ColorTuple[].
--- @param color ColorTuple | ColorTuple[]
--- @return ColorTuple[]
local function normalize_colors(color)
  if type(color[1]) == "number" then
    --- @cast color ColorTuple
    return { color }
  else
    --- @cast color ColorTuple[]
    return color
  end
end

--- Get color for an ingredient (science pack).
---
--- @param item_name string Name of ItemPrototype of the ingredient
--- @return Color|nil color Color for the ingredient, or `nil` for non-registered ingredients.
function PrototypeColorRegistry.get(item_name)
  local colors = PrototypeColorRegistry.registered_colors[item_name]
  return colors and Utils.color_struct(colors[1])
end

--- Get all colors for an ingredient (science pack).
---
--- @param item_name string Name of ItemPrototype of the ingredient
--- @return Color[]|nil colors All colors for the ingredient, or `nil` for non-registered ingredients.
function PrototypeColorRegistry.get_all(item_name)
  local colors = PrototypeColorRegistry.registered_colors[item_name]
  if not colors then return nil end
  local result = {}
  for i = 1, #colors do
    result[i] = Utils.color_struct(colors[i])
  end
  return result
end

--- Set color(s) for an ingredient (science pack).
---
--- This overwrites the existing color with the same name.
---
--- @param item_name string Name of ItemPrototype of the ingredient
--- @param color ColorTuple | ColorTuple[] Color or colors for the ingredient.
function PrototypeColorRegistry.set(item_name, color)
  PrototypeColorRegistry.registered_colors[item_name] = normalize_colors(color)
end

--- Set colors for ingredients by a table.
---
--- This overwrites the existing colors with the same names.
---
--- @param item_name_to_color table<string, ColorTuple | ColorTuple[]> ItemPrototype name to color table.
function PrototypeColorRegistry.set_by_table(item_name_to_color)
  local registered_colors = PrototypeColorRegistry.registered_colors
  for item_name, color in pairs(item_name_to_color) do
    registered_colors[item_name] = normalize_colors(color)
  end
end

--- Register a color prefix for fallback lookup.
---
--- When an ingredient color is not found by exact name, each registered prefix is tried.
--- If the ingredient name starts with the prefix, the prefix is stripped and the base name is looked up.
---
--- @param prefix string Prefix string, e.g. "compressed-"
function PrototypeColorRegistry.add_prefix(prefix)
  local registered_prefixes = PrototypeColorRegistry.registered_prefixes
  registered_prefixes[#registered_prefixes + 1] = prefix
end

--- Register a color suffix for fallback lookup.
---
--- When an ingredient color is not found by exact name or prefix, each registered suffix is tried.
--- If the ingredient name ends with the suffix, the suffix is stripped and the base name is looked up.
---
--- @param suffix string Suffix string, e.g. "-compressed"
function PrototypeColorRegistry.add_suffix(suffix)
  local registered_suffixes = PrototypeColorRegistry.registered_suffixes
  registered_suffixes[#registered_suffixes + 1] = suffix
end

return PrototypeColorRegistry
