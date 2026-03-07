local Utils = require("scripts.shared.utils")
local config_ingredient_colors = require("scripts.shared.config.ingredient-colors")

--- Registry for colors of ingredients
---
--- @class ColorRegistry
local ColorRegistry = {
  --- Default colors for research
  --- @type ColorTuple[]
  default_research_colors = { { 1.0, 0.0, 1.0 } },
}
ColorRegistry.__index = ColorRegistry

if script then
  script.register_metatable("ColorRegistry", ColorRegistry)
end

--- @return ColorRegistry
function ColorRegistry.new()
  --- @class ColorRegistry
  local self = {
    --- Dictionary of ingredient colors. Key is ingredient's ItemPrototype name.
    ingredient_colors = config_ingredient_colors,
  }
  return setmetatable(self, ColorRegistry)
end

--- Set color for an ingredient (science pack)
---
--- @param name string Name of ItemPrototype of the ingredient
--- @param color Color Color for the ingredient.
function ColorRegistry:set_ingredient_color(name, color)
  if self.ingredient_colors == config_ingredient_colors then
    -- We should make a copy for modifying it
    self.ingredient_colors = table.deepcopy(config_ingredient_colors)
  end
  self.ingredient_colors[name] = Utils.color_tuple(color)
end

--- Get color for an ingredient (science pack)
---
--- @param name string Name of ItemPrototype of the ingredient
--- @return Color|nil color Color for the ingredient, or `nil` for non-registered ingredients.
function ColorRegistry:get_ingredient_color(name)
  local color = self.ingredient_colors[name]
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
    for _, ingredient in ipairs(tech.research_unit_ingredients) do
      if not ingredient_colors[ingredient.name] then
        not_found[ingredient.name] = true
      end
    end
  end

  if next(not_found) ~= nil then
    local names = {}
    for name, _ in pairs(not_found) do
      names[#names + 1] = name
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

--- Get colors of ingredients for research of technology.
---
--- If calling on the same technology multiple times, the result should be cached by the caller.
---
--- @param technology LuaTechnology|LuaTechnologyPrototype Technology, or its prototype
--- @return ColorTuple[]
function ColorRegistry:get_colors_for_research(technology)
  --- @type ColorTuple[]
  local colors = {}
  local ingredient_colors = self.ingredient_colors
  for _, ingredient in ipairs(technology.research_unit_ingredients) do
    local color = ingredient_colors[ingredient.name]
    if color then
      colors[#colors + 1] = color
    end
  end
  if #colors == 0 then
    colors = self.default_research_colors
  end
  return colors
end

return ColorRegistry
