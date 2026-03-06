local Utils = {}

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

--- Make a MapPositionRect for an entity
---
--- @param entity LuaEntity
--- @return MapPositionRect
function Utils.get_entity_rect(entity)
  local position = entity.position
  local pos_x = position.x or position[1]
  local pos_y = position.y or position[2]
  return {
    pos_x,
    pos_y,
    pos_x + entity.tile_width,
    pos_y + entity.tile_height,
  }
end

return Utils
