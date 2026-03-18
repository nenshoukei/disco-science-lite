--- AAI Industry by Earendel
--- https://mods.factorio.com/mod/aai-industry

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

if mods["aai-industry"] then
  LabPrototypeModifier.set_animation_freeze(
    "__aai-industry__/graphics/entity/burner-lab/burner-lab.png",
    1
  )
  LabPrototypeModifier.set_layer_removal(
    "__aai-industry__/graphics/entity/burner-lab/burner-lab-light.png"
  )

  local is_blinking_disabled = settings.startup[ "mks-dsl-disable-lab-blinking" --[[$DISABLE_LAB_BLINKING_NAME]] ].value
  data:extend({
    {
      type = "animation",
      name = "mks-dsl" --[[$PREFIX]] .. "burner-lab-overlay",
      filename = "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "aai-industry/burner-lab-overlay.png",
      blend_mode = "additive",
      draw_as_glow = true,
      width = 194,
      height = 174,
      frame_count = 33,
      line_length = 11,
      animation_speed = 1 / 3,
      scale = 0.5,
      frame_sequence = is_blinking_disabled and { 2, 9, 12, 13, 26, 27 } or nil,
    },
  })

  PrototypeLabRegistry.register("burner-lab", {
    animation = "mks-dsl" --[[$PREFIX]] .. "burner-lab-overlay",
  })
end
