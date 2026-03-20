--- Pyanodons mods by pyanodon
--- https://mods.factorio.com/user/pyanodon

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

if mods["pyalienlife"] then
  PrototypeColorRegistry.set_by_table({
    ["py-science-pack-1"] = { 0.95, 0.48, 0.14 },
    ["py-science-pack-2"] = { 0.90, 0.40, 0.14 },
    ["py-science-pack-3"] = { 0.76, 0.13, 0.10 },
    ["py-science-pack-4"] = { 0.93, 0.37, 0.14 },
  })
end

if mods["pyfusionenergy"] then
  PrototypeColorRegistry.set("production-science-pack", { 1.00, 0.27, 0.77 })
end

if mods["pycoalprocessing"] and mods["pycoalprocessinggraphics"] then
  -- The mod only supports the original DiscoScience by `mods["DiscoScience"]` guard.
  -- So, we need to apply the same logic onto the lab prototype.

  LabPrototypeModifier.set_filename_replacement(
    "__pycoalprocessinggraphics__/graphics/entity/lab-mk01/raw.png",
    "__pycoalprocessinggraphics__/graphics/entity/lab-mk01/raw-bw.png"
  )
  LabPrototypeModifier.set_layer_removal(
    "__pycoalprocessinggraphics__/graphics/entity/lab-mk01/l.png"
  )
  LabPrototypeModifier.set_layer_removal(
    "__pycoalprocessinggraphics__/graphics/entity/lab-mk01/beam.png"
  )

  data:extend({
    {
      type = "animation",
      name = "mks-dsl" --[[$PREFIX]] .. "pyanodon-lab-overlay",
      layers = {
        {
          filename = "__pycoalprocessinggraphics__/graphics/entity/lab-mk01/l-bw.png",
          blend_mode = "additive",
          draw_as_glow = true,
          width = 160,
          height = 384,
          frame_count = 1,
          repeat_count = 60,
          animation_speed = 1 / 5,
          shift = util.by_pixel(0, -112),
        },
        {
          filename = "__pycoalprocessinggraphics__/graphics/entity/lab-mk01/beam-bw.png",
          blend_mode = "additive",
          draw_as_glow = true,
          width = 96,
          height = 128,
          frame_count = 60,
          line_length = 20,
          animation_speed = 1 / 4,
          shift = util.by_pixel(32, -112),
        },
      },
    },
  })

  -- Overrides the base lab registration
  PrototypeLabRegistry.register("lab", {
    animation = "mks-dsl" --[[$PREFIX]] .. "pyanodon-lab-overlay",
  })
end
