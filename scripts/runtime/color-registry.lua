local Utils = require("scripts.shared.utils")

--- Registry for colors of research ingredients
---
--- @class ColorRegistry
local ColorRegistry = {
  --- Default color for research
  --- @type ColorTuple
  default_research_color = { 0.27, 0.44, 0.93 },
}
ColorRegistry.__index = ColorRegistry

--- @param color_overrides table<string, ColorTuple>?
--- @return ColorRegistry
function ColorRegistry.new(color_overrides)
  --- @class ColorRegistry
  local self = {
    --- Dictionary of registered ingredient colors. Key is ingredient's ItemPrototype name.
    --- Includes pre-expanded entries for all registered prefix/suffix combinations.
    --- @type table<string, ColorTuple>
    registered_colors = {},
    --- Runtime overrides persisted in storage. Reference to storage.color_overrides.
    --- @type table<string, ColorTuple>
    overrides = color_overrides or {},
    --- Ingredient color prefixes for fallback lookup. Loaded from prototype mod-data.
    --- @type string[]
    color_prefixes = {},
    --- Ingredient color suffixes for fallback lookup. Loaded from prototype mod-data.
    --- @type string[]
    color_suffixes = {},
  }
  return setmetatable(self, ColorRegistry)
end

--- Set color for an ingredient (science pack)
---
--- @param item_name string Name of ItemPrototype of the ingredient
--- @param color Color Color for the ingredient.
function ColorRegistry:set_ingredient_color(item_name, color)
  local tuple = Utils.color_tuple(color)
  local registered_colors = self.registered_colors
  registered_colors[item_name] = tuple
  self.overrides[item_name] = tuple
  -- Expand derived entries for all loaded prefixes and suffixes.
  local color_prefixes = self.color_prefixes
  for j = 1, #color_prefixes do
    local derived = color_prefixes[j] .. item_name
    if registered_colors[derived] == nil then
      registered_colors[derived] = tuple
    end
  end
  local color_suffixes = self.color_suffixes
  for j = 1, #color_suffixes do
    local derived = item_name .. color_suffixes[j]
    if registered_colors[derived] == nil then
      registered_colors[derived] = tuple
    end
  end
end

--- Get color for an ingredient (science pack)
---
--- @param item_name string Name of ItemPrototype of the ingredient
--- @return Color|nil color Color for the ingredient, or `nil` for non-registered ingredients.
function ColorRegistry:get_ingredient_color(item_name)
  local color = self.registered_colors[item_name]
  return color and Utils.color_struct(color)
end

--- Validate technology prototypes
---
--- It scans all technology prototypes, and checks if their researching ingredients are registered.
--- If there is any ingredient not registered, write logs for them.
---
--- @param all_prototypes LuaPrototypes? Prototypes to be scanned. Defaults to the global `prototypes`.
--- @return string[]|nil # Names of technology prototypes not registered. `nil` if all ingredients registered.
function ColorRegistry:validate_technology_prototypes(all_prototypes)
  all_prototypes = all_prototypes or prototypes
  local registered_colors = self.registered_colors

  --- @type table<string, boolean>
  local not_found = {}
  for _, tech in pairs(all_prototypes.technology) do
    local ingredients = tech.research_unit_ingredients
    for i = 1, #ingredients do
      local name = ingredients[i].name
      if not registered_colors[name] then
        not_found[name] = true
      end
    end
  end

  if next(not_found) ~= nil then
    local names = {}
    local i = 1
    for name, _ in pairs(not_found) do
      names[i] = name
      i = i + 1
    end
    table.sort(names)
    log(
      "Disco Science Lite encountered the following ingredients with no registered color: " ..
      table.concat(names, ", ")
    )
    return names
  else
    return nil
  end
end

--- Load ingredient colors from the prototype stage mod-data.
---
--- Always replaces existing colors with a fresh copy from the prototype data,
--- then re-applies runtime overrides on top, then pre-expands prefix/suffix entries.
function ColorRegistry:load_prototype_colors()
  local mod_data = prototypes.mod_data[ "mks-dsl-prototype-data" --[[$PROTOTYPE_DATA_MOD_DATA_NAME]] ]
  if mod_data then
    local data = mod_data.data --[[@as DiscoSciencePrototypeData]]
    self.registered_colors = Utils.table_deep_copy(data.registered_colors)
    self.color_prefixes = Utils.table_deep_copy(data.registered_color_prefixes)
    self.color_suffixes = Utils.table_deep_copy(data.registered_color_suffixes)
  else
    self.registered_colors = {}
    self.color_prefixes = {}
    self.color_suffixes = {}
  end
  -- Re-apply runtime overrides on top of prototype data.
  for name, color in pairs(self.overrides) do
    self.registered_colors[name] = color
  end
  Utils.pre_expand_with_affixes(self.registered_colors, self.color_prefixes, self.color_suffixes)
end

--- Get colors of ingredients for research of technology.
---
--- If calling on the same technology multiple times, the result should be cached by the caller.
---
--- Saturation blends each color toward its perceived luminance (gray), using the formula:
---   result = luminance + (component - luminance) * saturation
--- Brightness then scales all components uniformly.
---
--- @param technology LuaTechnology|LuaTechnologyPrototype Technology, or its prototype
--- @param saturation number? Saturation multiplier in range [0.0, 1.0]. Defaults to 1.0.
--- @param brightness number? Brightness multiplier in range [0.0, 1.0]. Defaults to 1.0.
--- @return ColorTuple[]
function ColorRegistry:get_colors_for_research(technology, saturation, brightness)
  saturation = saturation or 1.0
  brightness = brightness or 1.0
  --- @type ColorTuple[]
  local colors = {}
  local n_colors = 0
  local registered_colors = self.registered_colors
  local ingredients = technology.research_unit_ingredients
  for i = 1, #ingredients do
    local name = ingredients[i].name
    local color = registered_colors[name]
    if color then
      n_colors = n_colors + 1
      local r, g, b = color[1], color[2], color[3]
      local lum = 0.299 * r + 0.587 * g + 0.114 * b
      colors[n_colors] = {
        (lum + (r - lum) * saturation) * brightness,
        (lum + (g - lum) * saturation) * brightness,
        (lum + (b - lum) * saturation) * brightness,
      }
    end
  end
  if n_colors == 0 then
    local color = self.default_research_color
    local r, g, b = color[1], color[2], color[3]
    local lum = 0.299 * r + 0.587 * g + 0.114 * b
    colors[1] = {
      (lum + (r - lum) * saturation) * brightness,
      (lum + (g - lum) * saturation) * brightness,
      (lum + (b - lum) * saturation) * brightness,
    }
  end
  return colors
end

return ColorRegistry
