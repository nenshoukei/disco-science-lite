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
    --- Dictionary of ingredient colors. Key is ingredient's ItemPrototype name.
    --- @type table<string, ColorTuple>
    ingredient_colors = {},
    --- Runtime overrides persisted in storage. Reference to storage.color_overrides.
    --- @type table<string, ColorTuple>
    overrides = color_overrides or {},
  }
  return setmetatable(self, ColorRegistry)
end

--- Set color for an ingredient (science pack)
---
--- @param item_name string Name of ItemPrototype of the ingredient
--- @param color Color Color for the ingredient.
function ColorRegistry:set_ingredient_color(item_name, color)
  local tuple = Utils.color_tuple(color)
  self.ingredient_colors[item_name] = tuple
  self.overrides[item_name] = tuple
end

--- Get color for an ingredient (science pack)
---
--- @param item_name string Name of ItemPrototype of the ingredient
--- @return Color|nil color Color for the ingredient, or `nil` for non-registered ingredients.
function ColorRegistry:get_ingredient_color(item_name)
  local color = self.ingredient_colors[item_name]
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
  local ingredient_colors = self.ingredient_colors

  --- @type table<string, boolean>
  local not_found = {}
  for _, tech in pairs(all_prototypes.technology) do
    local ingredients = tech.research_unit_ingredients
    for i = 1, #ingredients do
      local ingredient = ingredients[i]
      if not ingredient_colors[ingredient.name] then
        not_found[ingredient.name] = true
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
--- then re-applies runtime overrides on top.
function ColorRegistry:load_prototype_colors()
  local mod_data = prototypes.mod_data[ "mks-dsl-ingredient-colors" --[[$INGREDIENT_COLORS_MOD_DATA_NAME]] ]
  if mod_data then
    self.ingredient_colors = Utils.table_deep_copy(mod_data.data --[[@as table<string, ColorTuple>]])
  else
    self.ingredient_colors = {}
  end
  -- Re-apply runtime overrides on top of prototype data.
  for name, color in pairs(self.overrides) do
    self.ingredient_colors[name] = color
  end
end

--- Get colors of ingredients for research of technology.
---
--- If calling on the same technology multiple times, the result should be cached by the caller.
---
--- @param technology LuaTechnology|LuaTechnologyPrototype Technology, or its prototype
--- @param intensity number? Intensity multiplier in range [0.0, 1.0]. Defaults to 1.0.
--- @return ColorTuple[]
function ColorRegistry:get_colors_for_research(technology, intensity)
  intensity = intensity or 1.0
  --- @type ColorTuple[]
  local colors = {}
  local n_colors = 0
  local ingredient_colors = self.ingredient_colors
  local ingredients = technology.research_unit_ingredients
  for i = 1, #ingredients do
    local color = ingredient_colors[ingredients[i].name]
    if color then
      n_colors = n_colors + 1
      colors[n_colors] = { color[1] * intensity, color[2] * intensity, color[3] * intensity }
    end
  end
  if n_colors == 0 then
    local color = self.default_research_color
    colors[1] = { color[1] * intensity, color[2] * intensity, color[3] * intensity }
  end
  return colors
end

return ColorRegistry
