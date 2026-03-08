--- @meta

--- @alias ColorTuple [number, number, number]
--- @alias ColorStruct Color.0

--- @alias MapPositionTuple [number, number]
--- @alias MapPositionStruct MapPosition.0
--- @alias MapPositionRect [number, number, number, number] left, top, right, bottom

--- @alias data.AnyTriggerItem (data.DirectTriggerItem)|(data.AreaTriggerItem)|(data.LineTriggerItem)|(data.ClusterTriggerItem)

--- A lab registration defining the overlay animation and scale.
--- @class LabRegistration
--- @field animation string? Name of AnimationPrototype to be used as an overlay. If `nil`, the default lab overlay is used.
--- @field scale integer? Scale of the lab. Default scale is `1`.
