local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

data:extend({
  {
    type = "mod-data",
    name = "mks-dsl-registered-labs" --[[$REGISTERED_LABS_MOD_DATA_NAME]],
    data = PrototypeLabRegistry.registered_labs,
  },
  {
    type = "mod-data",
    name = "mks-dsl-excluded-labs" --[[$EXCLUDED_LABS_MOD_DATA_NAME]],
    data = PrototypeLabRegistry.excluded_labs,
  },
  {
    type = "mod-data",
    name = "mks-dsl-ingredient-colors" --[[$INGREDIENT_COLORS_MOD_DATA_NAME]],
    data = PrototypeColorRegistry.registered_colors,
  },
  {
    type = "mod-data",
    name = "mks-dsl-ingredient-color-prefixes" --[[$INGREDIENT_COLOR_PREFIXES_MOD_DATA_NAME]],
    data = PrototypeColorRegistry.registered_prefixes,
  },
})
