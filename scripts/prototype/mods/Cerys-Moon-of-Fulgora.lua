--- Cerys by thesixthroc
--- https://mods.factorio.com/mod/Cerys-Moon-of-Fulgora

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local table_merge = require("scripts.shared.utils").table_merge

if mods["Cerys-Moon-of-Fulgora"] then
  PrototypeColorRegistry.set("cerysian-science-pack", { 0.65, 1, 0.9 })

  LabPrototypeModifier.set_layer_removal(
    "__Cerys-Moon-of-Fulgora__/graphics/entity/cerys-lab/cerys-lab-front-shadow.png"
  )
  LabPrototypeModifier.set_layer_removal(
    "__Cerys-Moon-of-Fulgora__/graphics/entity/cerys-lab/cerys-lab-front.png"
  )

  data:extend({
    table_merge(
      data.raw["animation"][ "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]] ],
      {
        name = "mks-dsl" --[[$PREFIX]] .. "cerys-lab-overlay",
        scale = 0.68,
      }
    ),
    {
      type = "animation",
      name = "mks-dsl" --[[$PREFIX]] .. "cerys-lab-companion",
      layers = {
        {
          filename = "__Cerys-Moon-of-Fulgora__/graphics/entity/cerys-lab/cerys-lab-front-shadow.png",
          width = 347,
          height = 267,
          scale = 0.68,
          shift = util.by_pixel(10, 0),
        },
        {
          -- Note: cerys-lab-front.png has a dark texture inside the dome which makes the overlay darker.
          --       To avoid this, we need a dome image without the dark texture, but it is not allowed to
          --       make any derivations from the mod by its license. So, we stay it as-is.
          filename = "__Cerys-Moon-of-Fulgora__/graphics/entity/cerys-lab/cerys-lab-front.png",
          width = 347,
          height = 267,
          scale = 0.68,
          shift = util.by_pixel(10, 0),
        },
      },
    },
  })

  PrototypeLabRegistry.register("cerys-lab", {
    animation = "mks-dsl" --[[$PREFIX]] .. "cerys-lab-overlay",
    companion = "mks-dsl" --[[$PREFIX]] .. "cerys-lab-companion",
  })
end
