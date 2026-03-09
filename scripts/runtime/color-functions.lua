local consts = require("scripts.shared.consts")

--- @class ColorFunctions
local ColorFunctions = {}

local random = math.random

-- Constants for pre-processing. These will be embedded as numeric literals.
local CONSTANTS = {
  INV_PI = 1 / math.pi,
  INV_TWO_PI = 1 / (2 * math.pi),
  INV_8 = 1 / 8,
  INV_9 = 1 / 9,
  INV_10 = 1 / 10,
  INV_30 = 1 / 30,
  INV_40 = 1 / 40,
  INV_50 = 1 / 50,
  INV_1024 = 1 / 1024,
}

--- Template for the inlined interpolation logic.
---
--- Placeholders:
---   1: T_EXPRESSION - The expression to calculate 't' (with literals already embedded).
---   2: TRANSITION_SHARPNESS - The sharpness value.
local INLINE_TEMPLATE = [[
local modf = math.modf
local abs = math.abs
local sqrt = math.sqrt
local atan2 = math.atan2
local floor = math.floor
local max = math.max

--- @type ColorFunction
return function (output, phase, colors, n_colors, player_position, lab_position, chunk_x, chunk_y)
  local t = %s
  local base_index, f = modf(t)

  -- Normalize negative fractional part so that f is always in [0, 1).
  if f < 0 then
    base_index = base_index - 1
    f = f + 1
  end

  -- Scale and clamp the interpolation factor.
  f = f * %.18f
  if f > 1 then f = 1 end

  -- Choose the colors to interpolate between.
  local start_color = colors[base_index %% n_colors + 1]
  local end_color = colors[(base_index + 1) %% n_colors + 1]

  local sc1, sc2, sc3 = start_color[1], start_color[2], start_color[3]
  output[1] = sc1 + (end_color[1] - sc1) * f
  output[2] = sc2 + (end_color[2] - sc2) * f
  output[3] = sc3 + (end_color[3] - sc3) * f
end
]]

--- A function to calculate a color for a lab entity.
---
--- @alias ColorFunction fun(output: ColorTuple, phase: number, colors: ColorTuple[], n_colors: integer, player_position: MapPositionTuple, lab_position: MapPositionTuple, chunk_x: integer, chunk_y: integer)

--- Compiles a color function from a T expression.
---
--- @param name string Name for debugging.
--- @param t_expr string Expression for t.
--- @param sharpness number Transition sharpness.
--- @return ColorFunction
local function compile_function(name, t_expr, sharpness)
  -- Replace constant tokens (e.g. INV_PI) with numeric literals in the t_expr string.
  -- Using %f[%w] and %f[%W] ensures we only match full words (boundary check).
  for k, v in pairs(CONSTANTS) do
    t_expr = t_expr:gsub("%f[%w]" .. k .. "%f[%W]", string.format("%.18f", v))
  end

  local code = string.format(INLINE_TEMPLATE, t_expr, sharpness)

  -- Compiles the function. '@' prefix in chunk name makes it appear as a file in error logs.
  local chunk_name = "@color-function/" .. name
  return assert(load(code, chunk_name))()
end

--- @type ColorFunction[]
local functions = {
  -- [1] Radial
  compile_function("Radial",
    "sqrt((lab_position[1] - player_position[1])^2 + (lab_position[2] - player_position[2])^2) * INV_8 + phase * INV_40",
    2.0),

  -- [2] Angular
  compile_function("Angular",
    "(atan2(lab_position[2] - player_position[2], lab_position[1] - player_position[1]) * INV_TWO_PI + 0.5) * n_colors + phase * INV_30",
    2.0),

  -- [3] Horizontal
  compile_function("Horizontal", "abs(lab_position[1] - player_position[1]) * INV_10 + phase * INV_30", 2.0),

  -- [4] Vertical
  compile_function("Vertical", "abs(lab_position[2] - player_position[2]) * INV_10 + phase * INV_30", 2.0),

  -- [5] Diagonal
  compile_function("Diagonal",
    "abs(lab_position[1] - player_position[1] + lab_position[2] - player_position[2]) * INV_10 + phase * INV_30", 2.0),

  -- [6] Grid
  compile_function("Grid",
    "abs(floor((lab_position[1] - player_position[1]) * INV_9) + floor((lab_position[2] - player_position[2]) * INV_8)) + phase * INV_10",
    5.0),

  -- [7] Spiral
  compile_function("Spiral",
    "sqrt((lab_position[1] - player_position[1])^2 + (lab_position[2] - player_position[2])^2) * INV_8 - (atan2(lab_position[2] - player_position[2], lab_position[1] - player_position[1]) * INV_TWO_PI + 0.5) * n_colors + phase * INV_50",
    2.0),

  -- [8] Diamond
  compile_function("Diamond",
    "(abs(lab_position[1] - player_position[1]) + abs(lab_position[2] - player_position[2])) * INV_8 + phase * INV_40",
    2.0),

  -- [9] Kaleidoscope
  compile_function("Kaleidoscope",
    "atan2(abs(lab_position[2] - player_position[2]), abs(lab_position[1] - player_position[1])) * 2 * INV_PI * n_colors + sqrt((lab_position[1] - player_position[1])^2 + (lab_position[2] - player_position[2])^2) * INV_8 + phase * INV_40",
    3.0),

  -- [10] Square
  compile_function("Square",
    "max(abs(lab_position[1] - player_position[1]), abs(lab_position[2] - player_position[2])) * INV_8 + phase * INV_40",
    2.0),

  -- [11] Lattice
  compile_function("Lattice", [[
    (function()
      local fx = lab_position[1] % 32
      local fy = lab_position[2] % 32
      if fx > 16 then fx = 32 - fx end
      if fy > 16 then fy = 32 - fy end
      return sqrt(fx * fx + fy * fy) * INV_8 - phase * INV_40
    end)()
  ]], 2.0),

  -- [12] Pulse
  compile_function("Pulse", "phase * INV_40", 1.2),

  -- [13] Random
  compile_function("Random", [[
    (function()
      local phase_step = floor(phase * INV_10)
      local r = (floor(lab_position[1]) * 137 + floor(lab_position[2]) * 149 + phase_step * 163) % 1024 * INV_1024
      return r * n_colors
    end)()
  ]], 20.0),

  -- [14] Chunk Diagonal
  compile_function("ChunkDiagonal", "(chunk_x + chunk_y) * 0.5 + phase * INV_30", 10.0),

  -- [15] Chunk Random
  compile_function("ChunkRandom", "(chunk_x * 7 + chunk_y * 13) + phase * INV_40", 20.0),
}
ColorFunctions.functions = functions

local n_functions = #functions

--- Circularly interpolates between colors at time `t`.
--- (Maintained for testing compatibility; inlined functions use embedded logic)
---
--- @param output               ColorTuple    Output color tuple
--- @param t                    number        Time position (integer part = color index, fraction = blend factor)
--- @param colors               ColorTuple[]  Array of colors to interpolate
--- @param n_colors             integer       #colors, supplied by the caller
--- @param transition_sharpness number        1.0 = linear, >1 = sharper transition, <1 = smoother
function ColorFunctions.loop_interpolate(output, t, colors, n_colors, transition_sharpness)
  local base_index, f = math.modf(t)

  if f < 0 then
    base_index = base_index - 1
    f = f + 1
  end

  f = f * transition_sharpness
  if f > 1 then f = 1 end

  local start_color = colors[base_index % n_colors + 1]
  local end_color = colors[(base_index + 1) % n_colors + 1]

  local sc1, sc2, sc3 = start_color[1], start_color[2], start_color[3]
  output[1] = sc1 + (end_color[1] - sc1) * f
  output[2] = sc2 + (end_color[2] - sc2) * f
  output[3] = sc3 + (end_color[3] - sc3) * f
end

--- Choose a random color function.
---
--- If `prev_index` is given, that index will not be chosen.
---
--- @param prev_index integer? Previous color function index. `nil` for first time.
--- @return ColorFunction # Chosen color function.
--- @return integer # Index of chosen color function.
function ColorFunctions.choose_random(prev_index)
  local new_index
  if prev_index then
    new_index = random(1, n_functions - 1)
    if new_index >= prev_index then
      new_index = new_index + 1
    end
  else
    new_index = random(1, n_functions)
  end
  return functions[new_index], new_index
end

return ColorFunctions
