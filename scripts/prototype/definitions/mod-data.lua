local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

--- @type DiscoSciencePrototypeData
local prototype_data = {
  registered_labs = PrototypeLabRegistry.registered_labs,
  excluded_labs = PrototypeLabRegistry.excluded_labs,
  registered_colors = PrototypeColorRegistry.registered_colors,
  registered_color_prefixes = PrototypeColorRegistry.registered_prefixes,
  registered_color_suffixes = PrototypeColorRegistry.registered_suffixes,
  registered_lab_prefixes = PrototypeLabRegistry.registered_prefixes,
  registered_lab_suffixes = PrototypeLabRegistry.registered_suffixes,
}

data:extend({
  {
    type = "mod-data",
    name = "mks-dsl-prototype-data" --[[$PROTOTYPE_DATA_MOD_DATA_NAME]],
    data = prototype_data,
  },
})
