#!/usr/bin/env lua

package.path = "./?.lua;./?/init.lua;./lua_modules/share/lua/5.2/?.lua;" .. package.path
package.cpath = "./lua_modules/lib/lua/5.2/?.so;" .. package.cpath

local serpent = require("serpent")
local Regex = require("regkex")
local consts = require("scripts.shared.consts")

--- @param v string|number|boolean
--- @return string
local function to_literal(v)
  if type(v) == "string" then
    return serpent.line(v)
  elseif type(v) == "number" or type(v) == "boolean" then
    return tostring(v)
  else
    error("Unsupported constant type: " .. type(v))
  end
end

local STRING_LITERAL = [["(?:\\"|[^"])*"|'(?:\\'|[^'])*']]
local NUMERIC_LITERAL = "[+-]?[0-9]+(?:\\.[0-9]+)?" -- don't support `0xABC` or `123e-5`
local BOOLEAN_LITERAL = "\\b(?:true|false)\\b"
local LITERAL = "(?:" .. STRING_LITERAL .. "|" .. NUMERIC_LITERAL .. "|" .. BOOLEAN_LITERAL .. ")"

local NAKED_CONST = "\\b(?:consts\\.([A-Z0-9_]+))"
local TAGGED_LITERAL = LITERAL .. "(\\s*(?:,\\s*)?--\\s*\\[\\[\\s*\\$([^]]+?)\\s*\\]\\])"

--- For `expr --[[$const_expr]]`, captures: [1] = --[[$const_expr]], [2] = const_expr
--- For `consts.CONST_NAME`, captures: [3] = CONST_NAME
local consts_regex = Regex(TAGGED_LITERAL .. "|" .. NAKED_CONST)

--- @param content string
--- @return string
local function update_content(content)
  -- Update all existing consts expressions
  local processed_content = consts_regex:gsub(content, function (matched, matched_tag, tagged_const_expr, naked_const_name)
    if tagged_const_expr ~= "" then
      local eval_func, load_error = load("return " .. tagged_const_expr, tagged_const_expr, "bt", consts)
      if not eval_func then
        error("Failed to compile " .. tagged_const_expr .. ": " .. load_error)
      end

      local success, returned_value = pcall(eval_func)
      if not success then
        local error_const_name = string.match(returned_value, "attempt to concatenate global '([A-Z0-9_]+)'")
        if error_const_name then
          error("Constant not found: consts." .. error_const_name)
        else
          error("Failed to eval: " .. returned_value)
        end
      end
      if returned_value == nil then
        if string.match(tagged_const_expr, "^[A-Z0-9_]+$") then
          error("Constant not found: consts." .. tagged_const_expr)
        else
          error("Constant expression returned nil: " .. tagged_const_expr)
        end
      end

      local value_type = type(returned_value)
      if value_type ~= "string" and value_type ~= "number" and value_type ~= "boolean" then
        error("Constant expression returned non-literal value: " .. matched)
      end
      return to_literal(returned_value) .. matched_tag
    else
      local const_value = consts[naked_const_name]
      if const_value == nil then
        error("Constant not found: consts." .. naked_const_name)
      end
      return to_literal(const_value) .. " --[[$" .. naked_const_name .. "]]"
    end
  end)
  return processed_content
end

--- @param path string
local function process_file(path)
  local f = io.open(path, "r")
  if not f then return end
  local content = f:read("*a")
  f:close()

  local success, updated_content = pcall(update_content, content)
  if not success then
    io.stderr:write("Error processing " .. path .. ": " .. tostring(updated_content) .. "\n")
    return
  end

  if updated_content ~= content then
    local fw = io.open(path, "w")
    if fw then
      fw:write(updated_content)
      fw:close()
      print("Updated: " .. path)
    else
      io.stderr:write("Error writing to " .. path .. "\n")
    end
  end
end

-- If running as a script (not required by test)
if arg and arg[0] and arg[0]:match("update%-consts%.lua$") then
  -- Scan *.lua in `scripts/`, `spec/` or on top-level.
  local handle = io.popen(
    'find . \\( -regex "\\./[^/]*\\.lua" \\) -or \\( -path "./scripts/**.lua" -not -path "./scripts/shared/consts.lua" \\) -or \\( -path "./spec/**.lua" -not -path "./spec/tasks/update-consts_spec.lua" \\)')
  if handle then
    for path in handle:lines() do
      process_file(path)
    end
    handle:close()
  end
end

-- Return for testing
return {
  set_consts = function (new_consts) consts = new_consts end,
  update_content = update_content,
  to_literal = to_literal,
}
