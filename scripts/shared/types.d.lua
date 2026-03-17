--- @meta
error("This file cannot be executed")

--- @type consts
_G.consts = {}

--- Internal overlay settings for a lab. Includes auto-detected or runtime-overridden scale.
---
--- @class (exact) LabOverlaySettings
--- @field animation string? Name of AnimationPrototype to be used as an overlay.
--- @field scale number? Scale of the overlay.

--- @alias ColorTuple [number, number, number]
--- @alias ColorStruct Color.0

--- @alias MapPositionTuple [number, number]
--- @alias MapPositionStruct MapPosition.0
--- @alias MapPositionRect [number, number, number, number] left, top, right, bottom

--- @alias data.AnyTriggerItem (data.DirectTriggerItem)|(data.AreaTriggerItem)|(data.LineTriggerItem)|(data.ClusterTriggerItem)
