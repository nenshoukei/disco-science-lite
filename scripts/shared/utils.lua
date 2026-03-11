local Utils = {}

--- Make a deep copy of a table
---
--- This function is copied from util.lua provided by Factorio
---
--- @param object table
--- @return table
function Utils.table_deep_copy(object)
  local lookup_table = {}
  local function _copy(obj)
    if type(obj) ~= "table" then
      return obj
    elseif lookup_table[obj] then
      return lookup_table[obj]
    end
    local new_table = {}
    lookup_table[obj] = new_table
    for index, value in pairs(obj) do
      new_table[_copy(index)] = _copy(value)
    end
    return setmetatable(new_table, getmetatable(obj))
  end
  return _copy(object)
end

--- Make a ColorTuple for color
---
--- @param color Color
--- @return ColorTuple
function Utils.color_tuple(color)
  return {
    color[1] or color.r,
    color[2] or color.g,
    color[3] or color.b,
  }
end

--- Make a ColorStruct for color
---
--- @param color Color
--- @return ColorStruct
function Utils.color_struct(color)
  return {
    r = color[1] or color.r,
    g = color[2] or color.g,
    b = color[3] or color.b,
  }
end

--- Make a MapPositionTuple for position
---
--- @param position MapPosition
--- @return MapPositionTuple
function Utils.map_position_tuple(position)
  return {
    position[1] or position.x,
    position[2] or position.y,
  }
end

--- Make a MapPositionStruct for position
---
--- @param position MapPosition
--- @return MapPositionStruct
function Utils.map_position_struct(position)
  return {
    x = position[1] or position.x,
    y = position[2] or position.y,
  }
end

return Utils
