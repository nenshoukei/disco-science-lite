--- @class ColorFunctions
local ColorFunctions = {}

local format = string.format
local random = math.random
local PI = math.pi

--- A function to calculate a color for a lab entity.
---
--- Parameters:
--- - `output`   - Output color tuple.
--- - `phase`    - Continuously drifting value that shifts the color cycle position over time.
--- - `colors`   - An array of ColorTuple for picking from.
--- - `n_colors` - #colors
--- - `px`, `py` - Coordinates of the player. (`LuaPlayer::position`)
--- - `lx`, `ly` - Coordinates of the lab entity. (`LuaEntity::position`)
--- - `cx`, `cy` - Coordinates of the chunk where the lab entity locates at.
---
--- @alias ColorFunction fun(output: ColorTuple, phase: number, colors: ColorTuple[], n_colors: integer, px: number, py: number, lx: number, ly: number, cx: integer, cy: integer)

-- Constants for pre-processing. These will be embedded as numeric literals.
-- Inversed for folding constant divisions into multiplications. (much faster in Lua 5.2)
local CONSTANTS = {
  INV_PI     = format("%.18f", 1 / PI),
  INV_TWO_PI = format("%.18f", 1 / (2 * PI)),
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
--- The `t` value should by calculated by each color function's body.
--- `CONSTANTS` like `INV_PI` are embedded as numeric literals into the body.
---
--- Placeholders:
---   1: Function body - The function body to calculate 't'.
---   2: Transition sharpness - The sharpness value for interpolation.
local COLOR_FUNCTION_TEMPLATE = [[
  local modf = math.modf
  local abs = math.abs
  local sqrt = math.sqrt
  local atan2 = math.atan2
  local floor = math.floor
  local max = math.max

  --- @type ColorFunction
  return function (output, phase, colors, n_colors, px, py, lx, ly, cx, cy)
    local t
    %s
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
    local theta = atan2(ly - py, lx - px)
    t = (theta * INV_TWO_PI + 0.5) * n_colors + phase * INV_30
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
    local dist = sqrt(dx * dx + dy * dy)
    local theta = atan2(dy, dx)
    -- Radial distance expands outward; subtracting the normalized angle winds it into a spiral.
    t = dist * INV_8 - (theta * INV_TWO_PI + 0.5) * n_colors + phase * INV_50
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
    local theta = atan2(dy, dx)
    t = dist * INV_8 + theta * 2 * INV_PI * n_colors + phase * INV_40
  ]], 3),

  -- [10] Square: concentric square rings (Chebyshev distance) expand outward from the player position.
  compile_function("Square", [[
    t = max(abs(lx - px), abs(ly - py)) * INV_8 + phase * INV_40
  ]], 2),

  -- [11] Lattice: concentric rings emanate from a regular grid of source points fixed to the world,
  --   creating a repeating tiled pattern of circular rings across the map.
  compile_function("Lattice", [[
    -- Source grid: one ring center every 32 tiles.
    -- Fold lab coordinates into [0, 16] to find the distance to the nearest grid corner.
    local fx = lx % 32
    local fy = ly % 32
    if fx > 16 then fx = 32 - fx end
    if fy > 16 then fy = 32 - fy end
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

  -- [14] Chunk Diagonal: color cycles based on 45-degree diagonal axis by chunk size.
  compile_function("ChunkDiagonal", [[
    t = (cx + cy) * 0.5 + phase * INV_30
  ]], 10),

  -- [15] Chunk Random: color chages at random periodically by chunk size.
  compile_function("ChunkRandom", [[
    t = (cx * 7 + cy * 13) + phase * INV_40
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
  return f(output, 0, colors, n_colors, 0, 0, 0, 0, 0, 0)
end

return ColorFunctions
