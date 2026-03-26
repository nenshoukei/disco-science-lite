local Utils = {}

--- Make a deep copy of a table
---
--- This function is copied from util.lua provided by Factorio
---
--- @generic T : table
--- @param object T
--- @return T
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

--- Make a merged table from multiple tables.
---
--- For the same key, the later value overwrites the earlier value.
--- Be careful `nil` value is skipped in this process.
---
--- Values are shallow-copied.
---
--- @generic T : table
--- @param ... T
--- @return T
function Utils.table_merge(...)
  local tables = table.pack(...)
  local result = {}
  for i = 1, tables.n do
    for k, v in pairs(tables[i]) do
      result[k] = v
    end
  end
  return result
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

--- Pre-expand a table by adding prefix/suffix derived entries from a base snapshot.
---
--- For each prefix in `prefixes`, derives `prefix..name` entries.
--- For each suffix in `suffixes`, derives `name..suffix` entries.
--- Priority: exact > prefix[1] > prefix[2] > ... > suffix[1] > suffix[2] > ...
--- Existing entries are never overwritten (earlier entries take priority).
---
--- @generic T
--- @param base_table table<string, T>
--- @param prefixes string[]
--- @param suffixes string[]
function Utils.pre_expand_with_affixes(base_table, prefixes, suffixes)
  local base_snapshot = {}
  for name, value in pairs(base_table) do
    base_snapshot[name] = value
  end
  for j = 1, #prefixes do
    local prefix = prefixes[j]
    for name, value in pairs(base_snapshot) do
      local derived = prefix .. name
      if base_table[derived] == nil then
        base_table[derived] = value
      end
    end
  end
  for j = 1, #suffixes do
    local suffix = suffixes[j]
    for name, value in pairs(base_snapshot) do
      local derived = name .. suffix
      if base_table[derived] == nil then
        base_table[derived] = value
      end
    end
  end
end

return Utils
