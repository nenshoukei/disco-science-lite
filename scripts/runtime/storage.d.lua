--- @meta
error("This file cannot be executed")

--- @class (exact) AnimState
--- @field phase                number  Continuously drifting value passed to the color function.
--- @field phase_speed          number  Amount phase changes per tick.
--- @field color_function_index integer Index of the current color function.
--- @field saved_tick           integer game.tick when this state was last written (always at epoch start).

--- @class (exact) DiscoScienceStorage
--- @field color_overrides      table<string, ColorTuple>
--- @field lab_scale_overrides  table<string, number>
--- @field anim_state           AnimState
_G.storage = {}
