--- @meta

--- @alias ColorTuple [number, number, number]
--- @alias ColorStruct Color.0

--- @alias MapPositionTuple [number, number]
--- @alias MapPositionStruct MapPosition.0
--- @alias MapPositionRect [number, number, number, number] left, top, right, bottom

--- @alias data.AnyTriggerItem (data.DirectTriggerItem)|(data.AreaTriggerItem)|(data.LineTriggerItem)|(data.ClusterTriggerItem)

--- Settings for rendering a lab overlay.
--- @class (exact) LabOverlaySettings
--- @field animation string? Name of AnimationPrototype to be used as an overlay. (Default: the standard lab overlay is used)
--- @field scale integer? Scale of the lab. (Default: `1`)
