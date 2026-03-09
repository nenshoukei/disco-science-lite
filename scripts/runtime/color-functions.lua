--- @class ColorFunctions
local ColorFunctions = {}

local sqrt = math.sqrt
local modf = math.modf
local abs = math.abs
local atan2 = math.atan2
local floor = math.floor
local max = math.max
local random = math.random

-- Precomputed reciprocals: multiplication is faster than division in Lua 5.2,
-- because the compiler does not fold constant divisions into multiplications.
local INV_PI = 1 / math.pi
local INV_TWO_PI = INV_PI * 0.5 -- 1 / (2 * pi), for normalizing atan2 range [-pi, pi] to [-0.5, 0.5]
local INV_8 = 1 / 8
local INV_9 = 1 / 9
local INV_10 = 1 / 10
local INV_30 = 1 / 30
local INV_40 = 1 / 40
local INV_50 = 1 / 50
local INV_1024 = 1 / 1024

--- Circularly interpolates between colors at time `t`.
---
--- Accepts `n_colors` as an explicit argument so callers that
--- already hold `#colors` can pass it in without an extra table-length lookup.
---
--- @param output               ColorTuple    Output color tuple
--- @param t                    number        Time position (integer part = color index, fraction = blend factor)
--- @param colors               ColorTuple[]  Array of colors to interpolate
--- @param n_colors             integer       #colors, supplied by the caller
--- @param transition_sharpness number        1.0 = linear, >1 = sharper transition, <1 = smoother
local function loop_interpolate(output, t, colors, n_colors, transition_sharpness)
  local base_index, f = modf(t)

  -- Normalize negative fractional part so that f is always in [0, 1).
  if f < 0 then
    base_index = base_index - 1
    f = f + 1
  end

  -- Scale and clamp the interpolation factor without calling math.min.
  f = f * transition_sharpness
  if f > 1 then f = 1 end

  -- Choose the colors to interpolate between.
  local start_color = colors[base_index % n_colors + 1]
  local end_color = colors[(base_index + 1) % n_colors + 1]

  local sc1, sc2, sc3 = start_color[1], start_color[2], start_color[3]
  output[1] = sc1 + (end_color[1] - sc1) * f
  output[2] = sc2 + (end_color[2] - sc2) * f
  output[3] = sc3 + (end_color[3] - sc3) * f
end
ColorFunctions.loop_interpolate = loop_interpolate

--- A function to calculate a color for a lab entity.
---
--- Paramters:
--- - `output` - Output color tuple.
--- - `phase` - Continuously drifting value that shifts the color cycle position over time.
--- - `colors` - An array of ColorTuple for picking from.
--- - `n_colors` - #colors
--- - `player_position` - Position of the player. (`LuaPlayer::position`)
--- - `lab_position` - Position of the lab entity. (`LuaEntity::position`)
--- - `chunk_x` - X coordinate of the chunk where the lab entity locates at.
--- - `chunk_y` - Y coordinate of the chunk where the lab entity locates at.
---
--- @alias ColorFunction fun(output: ColorTuple, phase: number, colors: ColorTuple[], n_colors: integer, player_position: MapPositionTuple, lab_position: MapPositionTuple, chunk_x: integer, chunk_y: integer)

--- @type ColorFunction[]
local functions = {
  -- [1] Radial: color cycles based on the distance between the player and the lab.
  function (output, phase, colors, n_colors, player_position, lab_position)
    local dx = lab_position[1] - player_position[1]
    local dy = lab_position[2] - player_position[2]
    local t = sqrt(dx * dx + dy * dy) * INV_8 + phase * INV_40
    return loop_interpolate(output, t, colors, n_colors, 2)
  end,

  -- [2] Angular: color cycles around the lab position based on the angle from the player.
  function (output, phase, colors, n_colors, player_position, lab_position)
    local theta = atan2(lab_position[2] - player_position[2], lab_position[1] - player_position[1])
    -- Map angle [-pi, pi] to [0, 1], then scale to the color array length.
    local t = (theta * INV_TWO_PI + 0.5) * n_colors + phase * INV_30
    return loop_interpolate(output, t, colors, n_colors, 2)
  end,

  -- [3] Horizontal: color cycles based on horizontal separation only.
  function (output, phase, colors, n_colors, player_position, lab_position)
    local t = abs(lab_position[1] - player_position[1]) * INV_10 + phase * INV_30
    return loop_interpolate(output, t, colors, n_colors, 2)
  end,

  -- [4] Vertical: color cycles based on vertical separation only.
  function (output, phase, colors, n_colors, player_position, lab_position)
    local t = abs(lab_position[2] - player_position[2]) * INV_10 + phase * INV_30
    return loop_interpolate(output, t, colors, n_colors, 2)
  end,

  -- [5] Diagonal: color cycles based on 45-degree diagonal axis.
  function (output, phase, colors, n_colors, player_position, lab_position)
    local t = abs(lab_position[1] - player_position[1] + lab_position[2] - player_position[2]) * INV_10 + phase * INV_30
    return loop_interpolate(output, t, colors, n_colors, 2)
  end,

  -- [6] Grid: color cycles in discrete steps based on the lab's grid cell (9x8 units) relative to the player.
  function (output, phase, colors, n_colors, player_position, lab_position)
    local t = abs(floor((lab_position[1] - player_position[1]) * INV_9)
        + floor((lab_position[2] - player_position[2]) * INV_8))
      + phase * INV_10
    return loop_interpolate(output, t, colors, n_colors, 5)
  end,

  -- [7] Spiral: color follows a clockwise spiral outward from the player; the spiral slowly rotates over time.
  function (output, phase, colors, n_colors, player_position, lab_position)
    local dx = lab_position[1] - player_position[1]
    local dy = lab_position[2] - player_position[2]
    local dist = sqrt(dx * dx + dy * dy)
    local theta = atan2(dy, dx)
    -- Radial distance expands outward; subtracting the normalized angle winds it into a spiral.
    local t = dist * INV_8 - (theta * INV_TWO_PI + 0.5) * n_colors + phase * INV_50
    return loop_interpolate(output, t, colors, n_colors, 2)
  end,

  -- [8] Diamond: concentric diamond rings (Manhattan distance) expand outward from the player.
  function (output, phase, colors, n_colors, player_position, lab_position)
    local t = (abs(lab_position[1] - player_position[1]) + abs(lab_position[2] - player_position[2])) * INV_8
      + phase * INV_40
    return loop_interpolate(output, t, colors, n_colors, 2)
  end,

  -- [9] Kaleidoscope: 4-fold mirror symmetry (fold both axes) combined with radial distance bands.
  function (output, phase, colors, n_colors, player_position, lab_position)
    local dx = abs(lab_position[1] - player_position[1])
    local dy = abs(lab_position[2] - player_position[2])
    -- atan2 with both arguments non-negative stays in [0, pi/2]; multiply by 2*INV_PI to map to [0, 1].
    local theta = atan2(dy, dx)
    local dist = sqrt(dx * dx + dy * dy)
    local t = theta * 2 * INV_PI * n_colors + dist * INV_8 + phase * INV_40
    return loop_interpolate(output, t, colors, n_colors, 3)
  end,

  -- [10] Square: concentric square rings (Chebyshev distance) expand outward from the player position.
  function (output, phase, colors, n_colors, player_position, lab_position)
    local t = max(abs(lab_position[1] - player_position[1]), abs(lab_position[2] - player_position[2])) * INV_8
      + phase * INV_40
    return loop_interpolate(output, t, colors, n_colors, 2)
  end,

  -- [11] Lattice: concentric rings emanate from a regular grid of source points fixed to the world,
  --   creating a repeating tiled pattern of circular rings across the map.
  function (output, phase, colors, n_colors, _, lab_position)
    -- Source grid: one ring center every 32 tiles.
    -- Fold lab coordinates into [0, 16] to find the distance to the nearest grid corner.
    local fx = lab_position[1] % 32
    local fy = lab_position[2] % 32
    if fx > 16 then fx = 32 - fx end
    if fy > 16 then fy = 32 - fy end
    -- Rings expand outward over time: subtract phase to animate outward expansion.
    local t = sqrt(fx * fx + fy * fy) * INV_8 - phase * INV_40
    return loop_interpolate(output, t, colors, n_colors, 2)
  end,

  -- [12] Pulse: all labs change color in unison regardless of position.
  function (output, phase, colors, n_colors)
    local t = phase * INV_40
    return loop_interpolate(output, t, colors, n_colors, 1.2)
  end,

  -- [13] Random: color changes at random periodically.
  function (output, phase, colors, n_colors, _, lab_position)
    -- Discretize phase into steps to control the flicker rate.
    local phase_step = floor(phase * INV_10)
    -- LCG-style pseudo-random number.
    local r = (floor(lab_position[1]) * 137 + floor(lab_position[2]) * 149 + phase_step * 163) % 1024 * INV_1024
    local t = r * n_colors
    return loop_interpolate(output, t, colors, n_colors, 20)
  end,

  -- [14] Chunk Diagonal: color cycles based on 45-degree diagonal axis by chunk size.
  function (output, phase, colors, n_colors, _, _, chunk_x, chunk_y)
    local t = (chunk_x + chunk_y) * 0.5 + phase * INV_30
    return loop_interpolate(output, t, colors, n_colors, 10)
  end,

  -- [15] Chunk Random: color chages at random periodically by chunk size.
  function (output, phase, colors, n_colors, _, _, chunk_x, chunk_y)
    -- A simple hash to give each chunk a starting offset.
    local chunk_hash = (chunk_x * 7 + chunk_y * 13)
    local t = chunk_hash + phase * INV_40
    return loop_interpolate(output, t, colors, n_colors, 20)
  end,
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

return ColorFunctions
