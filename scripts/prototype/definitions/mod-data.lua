local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

--- @type DiscoSciencePrototypeData
local prototype_data = {
  registered_labs = PrototypeLabRegistry.registered_labs,
  excluded_labs = PrototypeLabRegistry.excluded_labs,
  registered_colors = PrototypeColorRegistry.registered_colors,
  registered_prefixes = PrototypeColorRegistry.registered_prefixes,
}

data:extend({
  {
    type = "mod-data",
    name = "mks-dsl-prototype-data" --[[$PROTOTYPE_DATA_MOD_DATA_NAME]],
    data = prototype_data,
  },
})
