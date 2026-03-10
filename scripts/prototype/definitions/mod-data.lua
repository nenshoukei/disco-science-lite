local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

data:extend({
  {
    type = "mod-data",
    name = "mks-dsl-lab-overlay-settings" --[[$LAB_OVERLAY_SETTINGS_MOD_DATA_NAME]],
    data = PrototypeLabRegistry.registered_labs,
  },
  {
    type = "mod-data",
    name = "mks-dsl-ingredient-colors" --[[$INGREDIENT_COLORS_MOD_DATA_NAME]],
    data = PrototypeColorRegistry.registered_colors,
  },
})
