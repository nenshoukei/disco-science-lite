--- @meta
error("This file cannot be executed")

--- @type consts
_G.consts = {}

--- Registration info for a lab to be colorized. Includes auto-detected or runtime-overridden scale.
---
--- @class (exact) LabRegistration
--- @field animation string? Name of AnimationPrototype to be used as an overlay.
--- @field companion string? Name of AnimationPrototype to be used as a companion, which is rendered over the overlay but not colorized.
--- @field scale number? Scale of the overlay.

--- @alias ColorTuple [number, number, number]
--- @alias ColorStruct Color.0

--- @alias MapPositionTuple [number, number]
--- @alias MapPositionStruct MapPosition.0
--- @alias MapPositionRect [number, number, number, number] left, top, right, bottom

--- @alias data.AnyTriggerItem (data.DirectTriggerItem)|(data.AreaTriggerItem)|(data.LineTriggerItem)|(data.ClusterTriggerItem)
