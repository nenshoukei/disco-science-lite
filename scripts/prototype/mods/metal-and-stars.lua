--- 🌐Metal and Stars by Alex Boucher
--- https://mods.factorio.com/mod/metal-and-stars

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

if mods["metal-and-stars"] then
  PrototypeColorRegistry.set_by_table({
    ["quantum-science-pack"] = { 1.00, 0.34, 0.91 },
    ["anomaly-science-pack"] = { 0.23, 0.18, 0.98 },
    ["nanite-science-pack"]  = { 0.89, 0.89, 0.89 },
    ["ring-science-pack"]    = { 0.94, 0.88, 0.39 },
  })

  LabPrototypeModifier.set_layer_removal(
    "__metal-and-stars-graphics__/graphics/entity/particle-accelerator/particle-accelerator-hr-animation-emission.png"
  )

  data:extend({
    {
      type = "animation",
      name = "mks-dsl-" --[[$NAME_PREFIX]] .. "microgravity-lab-overlay",
      blend_mode = "additive",
      draw_as_glow = true,
      width = 400,
      height = 400,
      frame_count = 60,
      animation_speed = 0.5,
      scale = 0.4,
      stripes = {
        {
          filename = "__metal-and-stars-graphics__/graphics/entity/particle-accelerator/particle-accelerator-hr-animation-emission.png",
          width_in_frames = 8,
          height_in_frames = 8,
        },
      },
    },
  })

  PrototypeLabRegistry.register("microgravity-lab", {
    animation = "mks-dsl-" --[[$NAME_PREFIX]] .. "microgravity-lab-overlay",
  })
end
