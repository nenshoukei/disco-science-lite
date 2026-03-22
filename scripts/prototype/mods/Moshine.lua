--- Moshine by snouz
--- https://mods.factorio.com/mod/Moshine

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

if mods["Moshine"] then
  PrototypeColorRegistry.set_by_table({
    ["datacell-empty"]           = { 0.90, 0.90, 0.90 },
    ["datacell-raw-data"]        = { 0.45, 0.78, 0.56 },
    ["datacell-ai-model-data"]   = { 0.51, 0.88, 1.00 },
    ["datacell-equation"]        = { 0.26, 0.46, 0.76 },
    ["datacell-solved-equation"] = { 0.93, 0.88, 0.48 },
  })

  LabPrototypeModifier.set_layer_removal(
    "__Moshine__/graphics/entity/supercomputer/supercomputer_glow.png",
    "__Moshine__/graphics/entity/supercomputer/supercomputer_light.png",
    "__Moshine__/graphics/entity/supercomputer/supercomputer_anim.png"
  )

  data:extend({
    {
      type = "animation",
      name = "mks-dsl-neural_computer-overlay" --[[$NAME_PREFIX .. "neural_computer-overlay"]],
      layers = {
        {
          filename = "__Moshine__/graphics/entity/supercomputer/supercomputer_glow.png",
          blend_mode = "additive",
          draw_as_glow = true,
          width = 400,
          height = 475,
          scale = 0.5,
          shift = { 0, -0.5 },
          repeat_count = 45,
        },
        {
          filename = "__Moshine__/graphics/entity/supercomputer/supercomputer_light.png",
          blend_mode = "additive",
          draw_as_light = true,
          width = 400,
          height = 475,
          scale = 0.5,
          shift = { 0, -0.5 },
          repeat_count = 45,
        },
        {
          filename = "__Moshine__/graphics/entity/supercomputer/supercomputer_anim.png",
          blend_mode = "additive",
          draw_as_glow = true,
          width = 180,
          height = 280,
          scale = 0.5,
          shift = { 0, -0.5 },
          frame_count = 45,
          line_length = 9,
          animation_speed = 0.5,
          apply_special_effect = true,
        },
      },
    },
  })

  PrototypeLabRegistry.register("neural_computer", {
    animation = "mks-dsl-neural_computer-overlay" --[[$NAME_PREFIX .. "neural_computer-overlay"]],
  })
end
