--- @meta
error("This file cannot be executed")

--- @type consts
_G.consts = {}

--- Registration info for a lab to be colorized. Includes auto-detected or runtime-overridden scale.
---
--- @class (exact) LabRegistration
--- @field animation string? Name of AnimationPrototype to be used as an overlay.
--- @field companion string? Name of AnimationPrototype to be used as a companion, which is rendered over the overlay but not colorized.
--- @field is_companion_under_overlay boolean? If `true`, the companion will be rendered under the overlay.
--- @field scale number? Scale of the overlay.

--- Prototype-stage data passed to the runtime stage via mod-data.
---
--- @class (exact) DiscoSciencePrototypeData
--- @field registered_labs table<string, LabRegistration>
--- @field excluded_labs table<string, boolean>
--- @field registered_colors table<string, ColorTuple>
--- @field registered_prefixes string[]

--- @alias ColorTuple [number, number, number]
--- @alias ColorStruct Color.0

--- @alias MapPositionTuple [number, number]
--- @alias MapPositionStruct MapPosition.0
--- @alias MapPositionRect [number, number, number, number] left, top, right, bottom

--- @alias data.AnyTriggerItem (data.DirectTriggerItem)|(data.AreaTriggerItem)|(data.LineTriggerItem)|(data.ClusterTriggerItem)
