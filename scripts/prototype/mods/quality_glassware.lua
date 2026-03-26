--- Quality Glassware by Hornwitser
--- https://mods.factorio.com/mod/quality_glassware

if not mods["quality_glassware"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local string_match = string.match

--- Pattern to extract color name from Quality Glassware icon filename
---
--- Examples:
--- * "cone_inverted_clear_green.png" => "green"
--- * "sphere_double_clear_blue.png" => "blue"
--- * "cube_empty.png" => "empty"
local ICON_PATTERN = "^__quality_glassware__/graphics/icons/[^/]+_([a-z]+)%.png$"

--- Color name to ColorTuple
---
--- Reference: https://forge.hornwitser.no/public/factorio-quality-glassware/src/branch/default/src/designs.lua#L3
--- @type table<string, ColorTuple>
local COLORS = {
  empty  = { 0.75, 0.75, 0.75 },
  red    = { 1.00, 0.29, 0.29 },
  green  = { 0.35, 0.98, 0.38 },
  black  = { 0.31, 0.31, 0.31 },
  cyan   = { 0.29, 0.94, 1.00 },
  purple = { 0.68, 0.31, 0.82 },
  yellow = { 1.00, 0.88, 0.24 },
  white  = { 1.00, 1.00, 1.00 },
  orange = { 1.00, 0.71, 0.25 },
  pink   = { 1.00, 0.33, 0.89 },
  blue   = { 0.22, 0.35, 0.98 },
  lime   = { 1.00, 0.98, 0.25 },
}

--- Extract color name from icon filename.
---
--- If it is not a Quality Glassware icon, returns `nil`.
---
--- @param filename string
--- @return ColorTuple|nil
local function filename_to_color(filename)
  local color_name = string_match(filename, ICON_PATTERN)
  if color_name then
    local color = COLORS[color_name]
    if color then return color end
  end
  return nil
end

--- Extract color name from tool prototype.
---
--- If it does not use a Quality Glassware icon, returns `nil`.
---
--- @param tool data.ToolPrototype
--- @return ColorTuple|nil
local function tool_to_color(tool)
  local icon = tool.icon
  if icon then
    local color = filename_to_color(icon)
    if color then return color end
  end

  local icons = tool.icons
  if icons then
    for i = 1, #icons do
      local color = filename_to_color(icons[i].icon)
      if color then return color end
    end
  end

  return nil
end

return {
  on_data_final_fixes = function ()
    local registered_colors = PrototypeColorRegistry.registered_colors

    -- Register all unregistered science-packs using Quality Glassware
    for _, tool in pairs(data.raw["tool"]) do
      if not registered_colors[tool.name] then
        local color = tool_to_color(tool)
        if color then
          PrototypeColorRegistry.set(tool.name, color)
        end
      end
    end
  end,
}
