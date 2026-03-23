--- Age of Production by AndreusAxolotl
--- https://mods.factorio.com/mod/Age-of-Production

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

if mods["Age-of-Production"] then
  LabPrototypeModifier.set_layer_removal(
    "__Age-of-Production-Graphics__/graphics/entity/quantum-computer/quantum-computer-hr-emission-1.png"
  )

  data:extend({
    {
      type = "animation",
      name = "mks-dsl-aop-quantum-computer-overlay" --[[$NAME_PREFIX .. "aop-quantum-computer-overlay"]],
      filename = "__disco-science-lite__/graphics/hurricane/fusion-reactor-hr-overlay.png"
      --[[$GRAPHICS_DIR .. "hurricane/fusion-reactor-hr-overlay.png"]],
      blend_mode = "additive",
      draw_as_glow = true,
      width = 400,
      height = 400,
      frame_count = 60,
      line_length = 8,
      animation_speed = 0.5,
      shift = util.by_pixel(0, -10),
      scale = 0.5,
    },
  })

  PrototypeLabRegistry.register("aop-quantum-computer", {
    animation = "mks-dsl-aop-quantum-computer-overlay" --[[$NAME_PREFIX .. "aop-quantum-computer-overlay"]],
  })
end
