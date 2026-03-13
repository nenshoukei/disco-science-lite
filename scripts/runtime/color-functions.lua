--- Color functions are functions to calculate lab colors based on time frame (phase), colors of research ingredients, player's position and lab's position.
---
--- These are dynamically generated and compiled to eliminate function call overhead:
---
--- - **Template Inlining:** Core interpolation logic and animation patterns are merged into a single string template.
--- - **Compilation:** The resulting code is compiled via `load()`, producing a flat, highly efficient function that avoids internal branching and nested calls.
--- - **Embedded Math:** Mathematical constants (e.g., `TWO_PI = 2 * math.pi`) are pre-calculated and embedded as literals during the compilation phase.
---
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
  PI     = format("%.18f", math.pi),
  TWO_PI = format("%.18f", 2 * math.pi),
}

--- Template for the color functions.
---
--- This template contains inlined circularly interpolation between `colors` at `t` value
--- with scaling by transition sharpness.
---
--- The `t` value should be calculated by each color function's body.
--- `CONSTANTS` like `TWO_PI` are embedded as numeric literals into the body.
---
--- Placeholders:
---   %s: Function body - The function body to calculate 't'.
---   %f: Transition sharpness - The sharpness value for interpolation.
local COLOR_FUNCTION_TEMPLATE = [[
  local sqrt = math.sqrt
  local atan2 = math.atan2

  --- @type ColorFunction
  return function (output, phase, colors, n_colors, px, py, lx, ly)
    local t
    %s

    -- Extract floor (i) and fractional part (f) from t using operator trick.
    -- (t %% 1) is equivalent to (t - floor(t)).
    local f_part = t %% 1
    local i = t - f_part
    local f = f_part * %.18f
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

local function_names = {}
ColorFunctions.function_names = function_names

--- Compiles a color function.
---
--- @param name string Function name for debugging.
--- @param body string Function body for the template.
--- @param transition_sharpness number Transition sharpness.
--- @return ColorFunction
local function compile_function(name, body, transition_sharpness)
  function_names[#function_names + 1] = name

  -- Replace constant tokens (e.g. TWO_PI) with numeric literals.
  body = body:gsub("[A-Z0-9_]+", CONSTANTS)

  local code = format(COLOR_FUNCTION_TEMPLATE, body, transition_sharpness)

  -- Compiles the function. '@' prefix in chunk name makes it appear as a file in error logs.
  local chunk_name = "@color-functions/" .. name
  return assert(load(code, chunk_name))()
end

--- @type ColorFunction[]
local functions = {
  -- In Factorio's Lua environment, even standard library function calls carry significant overhead compared to inline arithmetic.
  -- Benchmarks run inside the Factorio runtime (100,000+ iterations via `game.create_profiler()`) guided these choices:
  --
  -- * Avoid `math.abs`, `math.max`, `math.floor`:
  --     Replaced with inline equivalents (`x < 0 and -x or x`, `a > b and a or b`, `t - t % 1`). These are meaningfully faster in a hot loop.
  -- * `math.atan2` vs. Diamond Angle:
  --     For full 360° radial calculations, `math.atan2` is faster and more accurate than a Lua-based quadrant-branching approximation.
  --     However, for a single-quadrant case like the Kaleidoscope pattern, a simple division (`dy / (dx + dy)`) beats `atan2`.

  -- [1] Radial: color cycles based on the distance between the player and the lab.
  compile_function("Radial", [[
    local dx = lx - px
    local dy = ly - py
    t = sqrt(dx * dx + dy * dy) / 8 + phase
  ]], 2),

  -- [2] Angular: color cycles around the lab position based on the angle from the player.
  compile_function("Angular", [[
    t = (atan2(ly - py, lx - px) / TWO_PI + 0.5) * n_colors + phase
  ]], 2),

  -- [3] Horizontal: color cycles based on horizontal separation only.
  compile_function("Horizontal", [[
    local d = lx - px
    t = (d < 0 and -d or d) / 10 + phase
  ]], 2),

  -- [4] Vertical: color cycles based on vertical separation only.
  compile_function("Vertical", [[
    local d = ly - py
    t = (d < 0 and -d or d) / 10 + phase
  ]], 2),

  -- [5] Diagonal: color cycles based on 45-degree diagonal axis.
  compile_function("Diagonal", [[
    local d = lx - px + ly - py
    t = (d < 0 and -d or d) / 10 + phase
  ]], 2),

  -- [6] Grid: color cycles in discrete steps based on the lab's grid cell (9x8 units) relative to the player.
  compile_function("Grid", [[
    local dx = (lx - px) / 9
    local dy = (ly - py) / 8
    local fdx = dx - dx % 1
    local fdy = dy - dy % 1
    local val = fdx + fdy
    t = (val < 0 and -val or val) + phase
  ]], 5),

  -- [7] Spiral: color follows a clockwise spiral outward from the player; the spiral slowly rotates over time.
  compile_function("Spiral", [[
    local dx = lx - px
    local dy = ly - py
    t = sqrt(dx * dx + dy * dy) / 8 - (atan2(dy, dx) / TWO_PI + 0.5) * n_colors + phase
  ]], 2),

  -- [8] Diamond: concentric diamond rings (Manhattan distance) expand outward from the player.
  compile_function("Diamond", [[
    local dx = lx - px
    local dy = ly - py
    t = ((dx < 0 and -dx or dx) + (dy < 0 and -dy or dy)) / 8 + phase
  ]], 2),

  -- [9] Kaleidoscope: 4-fold mirror symmetry (fold both axes) combined with radial distance bands.
  compile_function("Kaleidoscope", [[
    local dx = lx - px
    local dy = ly - py
    dx = dx < 0 and -dx or dx
    dy = dy < 0 and -dy or dy
    local dist = dx + dy
    t = dist / 8 + (dy * n_colors) / (dist + 1e-9) + phase
  ]], 3),

  -- [10] Square: concentric square rings (Chebyshev distance) expand outward from the player position.
  compile_function("Square", [[
    local dx = lx - px
    local dy = ly - py
    dx = dx < 0 and -dx or dx
    dy = dy < 0 and -dy or dy
    t = (dx > dy and dx or dy) / 8 + phase
  ]], 2),

  -- [11] Lattice: repeating tiled pattern of circular rings across the map.
  compile_function("Lattice", [[
    local dx = (lx + 16) % 32 - 16
    local dy = (ly + 16) % 32 - 16
    dx = dx < 0 and -dx or dx
    dy = dy < 0 and -dy or dy
    t = sqrt(dx * dx + dy * dy) / 8 - phase
  ]], 2),

  -- [12] Pulse: all labs change color in unison regardless of position.
  compile_function("Pulse", [[
    t = phase
  ]], 1.2),

  -- [13] Random: color changes at random periodically.
  compile_function("Random", [[
    -- LCG-style pseudo-random number.
    local flx = lx - lx % 1
    local fly = ly - ly % 1
    local r = (flx * 137 + fly * 149 + (phase - phase % 1) * 163) % 1024 / 1024
    t = r * n_colors
  ]], 20),
}
ColorFunctions.functions = functions
ColorFunctions._compile_function = compile_function -- for benchmark
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
