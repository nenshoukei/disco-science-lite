--- @class ColorFunctions
local ColorFunctions = {}

local sqrt = math.sqrt
local modf = math.modf
local abs = math.abs
local atan2 = math.atan2
local floor = math.floor
local random = math.random

-- Precomputed reciprocals: multiplication is faster than division in Lua 5.2,
-- because the compiler does not fold constant divisions into multiplications.
local INV_PI = 1 / math.pi
local INV_8 = 1 / 8
local INV_9 = 1 / 9
local INV_10 = 1 / 10
local INV_30 = 1 / 30
local INV_40 = 1 / 40

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
--- - `tick` - Tick count provided by `on_tick` event.
--- - `colors` - An array of ColorTuple for picking from.
--- - `player_position` - Position of the player. (`LuaPlayer::position`)
--- - `lab_position` - Position of the lab entity. (`LuaEntity::position`)
---
--- @alias ColorFunction fun(output: ColorTuple, tick: number, colors: ColorTuple[], player_position: MapPositionTuple, lab_position: MapPositionTuple)

--- @type ColorFunction[]
local functions = {
  -- [1] Radial: color cycles based on the distance between the player and the lab.
  function (output, tick, colors, player_position, lab_position)
    local dx = lab_position[1] - player_position[1]
    local dy = lab_position[2] - player_position[2]
    local t = sqrt(dx * dx + dy * dy) * INV_8 + tick * INV_40
    return loop_interpolate(output, t, colors, #colors, 1.5)
  end,

  -- [2] Angular: color cycles around the lab position based on the angle from the player.
  function (output, tick, colors, player_position, lab_position)
    local theta = atan2(lab_position[2] - player_position[2], lab_position[1] - player_position[1])
    local n_colors = #colors
    -- Map angle [-pi, pi] to [0, 1], then scale to the color array length.
    local t = (theta * INV_PI * 0.5 + 0.5) * n_colors + tick * INV_30
    return loop_interpolate(output, t, colors, n_colors, 2)
  end,

  -- [3] Horizontal: color cycles based on horizontal separation only.
  function (output, tick, colors, player_position, lab_position)
    local t = abs(lab_position[1] - player_position[1]) * INV_10 + tick * INV_30
    return loop_interpolate(output, t, colors, #colors, 2)
  end,

  -- [4] Vertical: color cycles based on vertical separation only.
  function (output, tick, colors, player_position, lab_position)
    local t = abs(lab_position[2] - player_position[2]) * INV_10 + tick * INV_30
    return loop_interpolate(output, t, colors, #colors, 2)
  end,

  -- [5] Diagonal: color cycles based on 45-degree diagonal axis.
  function (output, tick, colors, player_position, lab_position)
    local t = abs(lab_position[1] - player_position[1] + lab_position[2] - player_position[2]) * INV_10 + tick * INV_30
    return loop_interpolate(output, t, colors, #colors, 2)
  end,

  -- [6] Grid: color cycles in discrete steps based on the lab's grid cell (9x8 units) relative to the player.
  function (output, tick, colors, player_position, lab_position)
    local t = abs(floor((lab_position[1] - player_position[1]) * INV_9)
        + floor((lab_position[2] - player_position[2]) * INV_8))
      + tick * INV_10
    return loop_interpolate(output, t, colors, #colors, 5)
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
