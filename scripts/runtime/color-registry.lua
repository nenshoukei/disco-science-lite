local Utils = require("scripts.shared.utils")

--- Registry for colors of research ingredients
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
    --- @type table<string, ColorTuple>
    ingredient_colors = {},
  }
  return setmetatable(self, ColorRegistry)
end

--- Set color for an ingredient (science pack)
---
--- @param item_name string Name of ItemPrototype of the ingredient
--- @param color Color Color for the ingredient.
function ColorRegistry:set_ingredient_color(item_name, color)
  self.ingredient_colors[item_name] = Utils.color_tuple(color)
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

--- Load ingredient colors from the prototype stage mod-data.
---
--- If `overwrites` is `true`, replaces all existing colors with the prototype data.
--- If `overwrites` is `false`, only adds colors for ingredients not yet registered.
---
--- @param overwrites boolean Whether to overwrite existing colors.
function ColorRegistry:load_prototype_colors(overwrites)
  local mod_data = prototypes.mod_data[ "mks-dsl-ingredient-colors" --[[$INGREDIENT_COLORS_MOD_DATA_NAME]] ]
  if not mod_data then return end
  local prototype_colors = mod_data.data --[[@as table<string, ColorTuple>]]

  if overwrites then
    self.ingredient_colors = Utils.table_deep_copy(prototype_colors)
  else
    local colors = self.ingredient_colors
    for name, color in pairs(prototype_colors) do
      if not colors[name] then
        colors[name] = color
      end
    end
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
  local ingredient_colors = self.ingredient_colors
  local ingredients = technology.research_unit_ingredients
  for i = 1, #ingredients do
    local color = ingredient_colors[ingredients[i].name]
    if color then
      colors[#colors + 1] = { color[1] * intensity, color[2] * intensity, color[3] * intensity }
    end
  end
  if #colors == 0 then
    local dc = self.default_research_colors
    for i = 1, #dc do
      local c = dc[i]
      colors[#colors + 1] = { c[1] * intensity, c[2] * intensity, c[3] * intensity }
    end
  end
  return colors
end

return ColorRegistry
