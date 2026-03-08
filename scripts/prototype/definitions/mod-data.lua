local consts = require("scripts.shared.consts")
local LabPrototypeRegistry = require("scripts.prototype.lab-prototype-registry")

data:extend({
  {
    type = "mod-data",
    name = consts.LAB_OVERLAY_SETTINGS_MOD_DATA_NAME,
    data = LabPrototypeRegistry.registered_labs,
  },
})
