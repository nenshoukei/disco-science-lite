--- @meta
error("This file cannot be executed")

--- @class (exact) DiscoScienceStorage
--- @field color_overrides     table<string, ColorTuple[]>
--- @field lab_scale_overrides table<string, number>
--- @field validation_pending  boolean?                    Set while the deferred technology validation has not run yet.
_G.storage = {}
