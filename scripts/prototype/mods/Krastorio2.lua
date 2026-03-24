--- Krastorio 2 by raiguard
--- https://mods.factorio.com/mod/Krastorio2
--- Krastorio 2 Spaced Out by Polka_37
--- https://mods.factorio.com/mod/Krastorio2-spaced-out

if not (mods["Krastorio2"] or mods["Krastorio2-spaced-out"]) then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
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

    PrototypeLabRegistry.register("kr-advanced-lab", {
      animation = "mks-dsl-kr-advanced-lab-overlay" --[[$NAME_PREFIX .. "kr-advanced-lab-overlay"]],
    })
    PrototypeLabRegistry.register("kr-singularity-lab", {
      animation = "mks-dsl-kr-singularity-lab-overlay" --[[$NAME_PREFIX .. "kr-singularity-lab-overlay"]],
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("kr-advanced-lab", function (modifier)
      local light = modifier:remove_layer("__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-light-anim.png")
      modifier:remove_layer("__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-light-anim.png") -- If has two light anim, so remove twice
      modifier:insert_mask_layer(
        "__Krastorio2Assets__/buildings/advanced-lab/advanced-lab-anim.png",
        "__disco-science-lite__/graphics/laborat/lab_albedo_anim-mask.png" --[[$GRAPHICS_DIR .. "laborat/lab_albedo_anim-mask.png"]]
      )

      if not light then return end
      data:extend({
        AnimationHelpers.convert_to_animation_prototype(light, {
          name = "mks-dsl-kr-advanced-lab-overlay" --[[$NAME_PREFIX .. "kr-advanced-lab-overlay"]],
          filename = "__disco-science-lite__/graphics/laborat/lab_albedo_anim-overlay.png" --[[$GRAPHICS_DIR .. "laborat/lab_albedo_anim-overlay.png"]],
          blend_mode = "additive",
          frame_count = 1,
        }),
      })
    end)

    AnimationHelpers.modify_on_animation("kr-singularity-lab", function (modifier)
      local glow_light = modifier:get_layer("__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-glow-light.png")
      if not glow_light then return end

      modifier:remove_layer("__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-glow.png")

      -- Use singularity-lab-glow-light.png (already grayscale) as a mask layer instead of a generated mask.
      modifier:insert_mask_layer(
        "__Krastorio2Assets__/buildings/singularity-lab/singularity-lab-working.png",
        glow_light.filename,
        AnimationHelpers.copy_geometric_properties(glow_light)
      )

      data:extend({
        AnimationHelpers.convert_to_animation_prototype(glow_light, {
          name = "mks-dsl-kr-singularity-lab-overlay" --[[$NAME_PREFIX .. "kr-singularity-lab-overlay"]],
          filename = "__disco-science-lite__/graphics/Krastorio2/singularity-lab-overlay.png" --[[$GRAPHICS_DIR .. "Krastorio2/singularity-lab-overlay.png"]],
          blend_mode = "additive",
          draw_as_glow = true,
          draw_as_light = false,
          frame_count = 1,
        }),
      })
    end)
  end,
}
