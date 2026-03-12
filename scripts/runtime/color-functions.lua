--- @class ColorFunctions
local ColorFunctions = {}

local format = string.format
local random = math.random

--- A function to calculate a color for a lab entity.
---
--- Parameters:
--- - `output`   - Output color tuple.
--- - `phase`    - Continuously drifting value that shifts the color cycle position over time.
--- - `colors`   - A flattened array of colors for picking from in format: `{ r, g, b, r, g, b, ... }`
--- - `n_colors` - Number of colors. `#colors / 3`.
--- - `px`, `py` - Coordinates of the player. (`LuaPlayer::position`)
--- - `lx`, `ly` - Coordinates of the lab entity. (`LuaEntity::position`)
---
--- @alias ColorFunction fun(output: ColorTuple, phase: number, colors: ColorTuple[], n_colors: integer, px: number, py: number, lx: number, ly: number)

-- Constants for pre-processing. These will be embedded as numeric literals.
-- Inversed for folding constant divisions into multiplications. (much faster in Lua 5.2)
local CONSTANTS = {
  INV_PI     = format("%.18f", 1 / math.pi),
  INV_TWO_PI = format("%.18f", 1 / (2 * math.pi)),
  INV_4      = format("%.18f", 1 / 4),
  INV_8      = format("%.18f", 1 / 8),
  INV_9      = format("%.18f", 1 / 9),
  INV_10     = format("%.18f", 1 / 10),
  INV_30     = format("%.18f", 1 / 30),
  INV_40     = format("%.18f", 1 / 40),
  INV_50     = format("%.18f", 1 / 50),
  INV_1024   = format("%.18f", 1 / 1024),
}

--- Template for the color functions.
---
--- This template contains inlined circularly interpolation between `colors` at `t` value
--- with scaling by transition sharpness.
---
--- The `t` value should be calculated by each color function's body.
--- `CONSTANTS` like `INV_PI` are embedded as numeric literals into the body.
---
--- Placeholders:
---   %s: Function body - The function body to calculate 't'.
---   %f: Transition sharpness - The sharpness value for interpolation.
local COLOR_FUNCTION_TEMPLATE = [[
  local abs = math.abs
  local sqrt = math.sqrt
  local atan2 = math.atan2
  local floor = math.floor
  local max = math.max

  --- @type ColorFunction
  return function (output, phase, colors, n_colors, px, py, lx, ly)
    local t
    %s

    -- Extract floor (i) and fractional part (f) from t.
    -- i is for color index and f is for interpolation factor.
    -- f is scaled by sharpness and clamped to [0, 1].
    local i = floor(t)
    local f = (t - i) * %.18f
    if f > 1 then f = 1 end

    -- Choose the colors to interpolate between.
    -- i can be negative but modulo (%%) always returns positive numbers.
    local i1 = (i %% n_colors) * 3
    local i2 = ((i + 1) %% n_colors) * 3

    local r1 = colors[i1 + 1]
    local g1 = colors[i1 + 2]
    local b1 = colors[i1 + 3]

    output[1] = r1 + (colors[i2 + 1] - r1) * f
    output[2] = g1 + (colors[i2 + 2] - g1) * f
    output[3] = b1 + (colors[i2 + 3] - b1) * f
  end
]]

--- Compiles a color function.
---
--- @param name string Function name for debugging.
--- @param body string Function body for the template.
--- @param transition_sharpness number Transition sharpness.
--- @return ColorFunction
local function compile_function(name, body, transition_sharpness)
  -- Replace constant tokens (e.g. INV_PI) with numeric literals.
  body = body:gsub("[A-Z0-9_]+", CONSTANTS)

  local code = format(COLOR_FUNCTION_TEMPLATE, body, transition_sharpness)

  -- Compiles the function. '@' prefix in chunk name makes it appear as a file in error logs.
  local chunk_name = "@color-functions/" .. name
  return assert(load(code, chunk_name))()
end

ColorFunctions.function_names = {
  "Radial",
  "Angular",
  "Horizontal",
  "Vertical",
  "Diagonal",
  "Grid",
  "Spiral",
  "Diamond",
  "Kaleidoscope",
  "Square",
  "Lattice",
  "Pulse",
  "Random",
}

--- @type ColorFunction[]
local functions = {
  -- [1] Radial: color cycles based on the distance between the player and the lab.
  compile_function("Radial", [[
    local dx = lx - px
    local dy = ly - py
    t = sqrt(dx * dx + dy * dy) * INV_8 + phase * INV_40
  ]], 2),

  -- [2] Angular: color cycles around the lab position based on the angle from the player.
  compile_function("Angular", [[
    local dx = lx - px
    local dy = ly - py

    -- Use diamond-angle approximation to avoid expensive atan2(dx, dy).
    local adx = abs(dx)
    local ady = abs(dy)
    local q = ady / (adx + ady + 1e-9)
    if dx < 0 then
      if dy < 0 then q = 2 + q else q = 2 - q end
    elseif dy < 0 then
      q = 4 - q
    end

    t = q * INV_4 * n_colors + phase * INV_30
  ]], 2),

  -- [3] Horizontal: color cycles based on horizontal separation only.
  compile_function("Horizontal", [[
    t = abs(lx - px) * INV_10 + phase * INV_30
  ]], 2),

  -- [4] Vertical: color cycles based on vertical separation only.
  compile_function("Vertical", [[
    t = abs(ly - py) * INV_10 + phase * INV_30
  ]], 2),

  -- [5] Diagonal: color cycles based on 45-degree diagonal axis.
  compile_function("Diagonal", [[
    t = abs(lx - px + ly - py) * INV_10 + phase * INV_30
  ]], 2),

  -- [6] Grid: color cycles in discrete steps based on the lab's grid cell (9x8 units) relative to the player.
  compile_function("Grid", [[
    t = abs(floor((lx - px) * INV_9) + floor((ly - py) * INV_8)) + phase * INV_10
  ]], 5),

  -- [7] Spiral: color follows a clockwise spiral outward from the player; the spiral slowly rotates over time.
  compile_function("Spiral", [[
    local dx = lx - px
    local dy = ly - py

    -- Use diamond-angle approximation to avoid expensive atan2(dx, dy).
    local adx = abs(dx)
    local ady = abs(dy)
    local dist = sqrt(dx * dx + dy * dy)
    local q = ady / (adx + ady + 1e-9)
    if dx < 0 then
      if dy < 0 then q = 2 + q else q = 2 - q end
    elseif dy < 0 then
      q = 4 - q
    end

    t = dist * INV_8 - q * INV_4 * n_colors + phase * INV_50
  ]], 2),

  -- [8] Diamond: concentric diamond rings (Manhattan distance) expand outward from the player.
  compile_function("Diamond", [[
    t = (abs(lx - px) + abs(ly - py)) * INV_8 + phase * INV_40
  ]], 2),

  -- [9] Kaleidoscope: 4-fold mirror symmetry (fold both axes) combined with radial distance bands.
  compile_function("Kaleidoscope", [[
    local dx = abs(lx - px)
    local dy = abs(ly - py)
    local dist = sqrt(dx * dx + dy * dy)

    -- Use diamond-angle approximation in the first quadrant.
    local q = dy / (dx + dy + 1e-9)

    t = dist * INV_8 + q * n_colors + phase * INV_40
  ]], 3),

  -- [10] Square: concentric square rings (Chebyshev distance) expand outward from the player position.
  compile_function("Square", [[
    t = max(abs(lx - px), abs(ly - py)) * INV_8 + phase * INV_40
  ]], 2),

  -- [11] Lattice: repeating tiled pattern of circular rings across the map.
  compile_function("Lattice", [[
    local fx = abs((lx + 16) % 32 - 16)
    local fy = abs((ly + 16) % 32 - 16)
    t = sqrt(fx * fx + fy * fy) * INV_8 - phase * INV_40
  ]], 2),

  -- [12] Pulse: all labs change color in unison regardless of position.
  compile_function("Pulse", [[
    t = phase * INV_40
  ]], 1.2),

  -- [13] Random: color changes at random periodically.
  compile_function("Random", [[
    -- Discretize phase into steps to control the flicker rate.
    local phase_step = floor(phase * INV_10)
    -- LCG-style pseudo-random number.
    local r = (floor(lx) * 137 + floor(ly) * 149 + phase_step * 163) % 1024 * INV_1024
    t = r * n_colors
  ]], 20),
}
ColorFunctions.functions = functions
local n_functions = #functions

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

--- This is just for testing the inlined interpolation.
---
--- DO NOT use this for production code since it dynamically compiles a color function.
---
--- @param output ColorTuple Output color tuple.
--- @param t number `t` value for testing.
--- @param colors ColorTuple[] Array of colors to interpolate.
--- @param n_colors integer #colors
--- @param transition_sharpness number Transition sharpness.
function ColorFunctions.test_inlined_interpolation(output, t, colors, n_colors, transition_sharpness)
  local f = compile_function("inlined_interpolation", format("t = %.18f", t), transition_sharpness)
  return f(output, 0, colors, n_colors, 0, 0, 0, 0)
end

return ColorFunctions
