local consts = require("scripts.shared.consts")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

data:extend({
  {
    type = "mod-data",
    name = consts.LAB_OVERLAY_SETTINGS_MOD_DATA_NAME,
    data = PrototypeLabRegistry.registered_labs,
  },
  {
    type = "mod-data",
    name = consts.INGREDIENT_COLORS_MOD_DATA_NAME,
    data = PrototypeColorRegistry.registered_colors,
  },
})
