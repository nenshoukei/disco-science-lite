--- Krastorio 2 by raiguard
--- https://mods.factorio.com/mod/Krastorio2
--- Krastorio 2 Spaced Out by Polka_37
--- https://mods.factorio.com/mod/Krastorio2-spaced-out

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

if mods["Krastorio2-spaced-out"] then
  PrototypeColorRegistry.set_by_table({
    ["electromagnetic-science-pack"]     = { 1.00, 0.00, 0.52 },
    ["metallurgic-science-pack"]         = { 1.00, 0.37, 0.02 },
    ["agricultural-science-pack"]        = { 0.67, 0.83, 0.00 },
    ["cryogenic-science-pack"]           = { 1.00, 0.10, 0.77 },
    ["promethium-science-pack"]          = { 0.24, 0.14, 0.34 },

    ["kr-electromagnetic-research-data"] = { 1.00, 0.27, 0.65 },
    ["kr-metallurgic-research-data"]     = { 1.00, 0.42, 0.12 },
    ["kr-agricultural-research-data"]    = { 0.72, 0.81, 0.08 },
    ["kr-cryogenic-research-data"]       = { 0.22, 0.42, 1.00 },
    ["kr-promethium-research-data"]      = { 0.16, 0.14, 0.21 },
  })
end

if mods["Krastorio2"] or mods["Krastorio2-spaced-out"] then
  PrototypeColorRegistry.set_by_table({
    ["automation-science-pack"]  = { 0.95, 0.09, 0.07 },
    ["logistic-science-pack"]    = { 0.08, 0.74, 0.17 },
    ["chemical-science-pack"]    = { 0.09, 0.26, 0.92 },
    ["production-science-pack"]  = { 0.78, 0.18, 0.62 },
    ["military-science-pack"]    = { 0.75, 0.75, 0.75 },
    ["utility-science-pack"]     = { 1.00, 0.66, 0.10 },
    ["space-science-pack"]       = { 0.48, 0.48, 0.48 },

    ["kr-blank-tech-card"]       = { 0.99, 0.99, 0.99 },
    ["kr-biter-research-data"]   = { 0.33, 0.33, 0.33 },
    ["kr-matter-research-data"]  = { 0.44, 0.86, 0.87 },
    ["kr-space-research-data"]   = { 0.78, 0.68, 0.66 },
    ["kr-basic-tech-card"]       = { 0.75, 0.46, 0.23 },
    ["kr-matter-tech-card"]      = { 0.04, 0.81, 0.87 },
    ["kr-advanced-tech-card"]    = { 1.00, 0.97, 0.27 },
    ["kr-singularity-tech-card"] = { 1.00, 0.00, 0.98 },
  })

  LabPrototypeModifier.set_layer_removal(
    "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-light-anim.png",
    "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-glow-light.png",
    "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-glow.png"
  )
  LabPrototypeModifier.set_layer_mask(
    "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-anim.png",
    "__disco-science-lite__/graphics/laborat/lab_albedo_anim-mask.png" --[[$GRAPHICS_DIR .. "laborat/lab_albedo_anim-mask.png"]]
  )
  -- Use singularity-lab-glow-light.png (already grayscale) as a mask layer instead of a generated mask.
  -- It is removed above (as draw_as_light), then re-inserted here as a regular opaque layer
  -- to desaturate the colored working animation in the glow areas.
  LabPrototypeModifier.set_layer_mask(
    "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-working.png",
    "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-glow-light.png",
    { width = 153, height = 117, shift = { 0, -0.8 }, line_length = 6, animation_speed = 0.85 }
  )

  data:extend({
    {
      type = "animation",
      name = "mks-dsl-kr-advanced-lab-overlay" --[[$NAME_PREFIX .. "kr-advanced-lab-overlay"]],
      filename = "__disco-science-lite__/graphics/laborat/lab_albedo_anim-overlay.png" --[[$GRAPHICS_DIR .. "laborat/lab_albedo_anim-overlay.png"]],
      blend_mode = "additive",
      draw_as_glow = true,
      width = 150,
      height = 150,
      frame_count = 1,
      shift = { 0, -0.05 },
      scale = 0.64,
    },
    {
      type = "animation",
      name = "mks-dsl-kr-singularity-lab-overlay" --[[$NAME_PREFIX .. "kr-singularity-lab-overlay"]],
      filename = "__disco-science-lite__/graphics/Krastorio2/singularity-lab-overlay.png" --[[$GRAPHICS_DIR .. "Krastorio2/singularity-lab-overlay.png"]],
      blend_mode = "additive",
      draw_as_glow = true,
      width = 520,
      height = 500,
      frame_count = 1,
      shift = { 0, -0.1 },
      scale = 0.5,
    },
  })

  PrototypeLabRegistry.register("kr-advanced-lab", {
    animation = "mks-dsl-kr-advanced-lab-overlay" --[[$NAME_PREFIX .. "kr-advanced-lab-overlay"]],
  })
  PrototypeLabRegistry.register("kr-singularity-lab", {
    animation = "mks-dsl-kr-singularity-lab-overlay" --[[$NAME_PREFIX .. "kr-singularity-lab-overlay"]],
  })
end
