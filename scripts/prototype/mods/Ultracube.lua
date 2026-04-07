--- Ultracube: Age of Cube by grandseiken
--- https://mods.factorio.com/mod/Ultracube

if not mods["Ultracube"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["cube-basic-contemplation-unit"]       = { 0.60, 0.60, 0.60 },
      ["cube-fundamental-comprehension-card"] = { 0.52, 0.98, 0.27 },
      ["cube-abstract-interrogation-card"]    = { 0.00, 0.99, 0.99 },
      ["cube-deep-introspection-card"]        = { 1.00, 0.18, 0.98 },
      ["cube-synthetic-premonition-card"]     = { 1.00, 1.00, 1.00 },
      ["cube-complete-annihilation-card"]     = { 1.00, 0.98, 0.44 },
    })

    PrototypeLabRegistry.register("cube-lab", {
      animation = "mks-dsl-cube-lab-overlay" --[[$NAME_PREFIX .. "cube-lab-overlay"]],
      companion = "mks-dsl-cube-lab-companion" --[[$NAME_PREFIX .. "cube-lab-companion"]],
      is_companion_under_overlay = true,
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("cube-lab", function (modifier)
      local light = modifier:remove_layer("__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-light-anim.png")
      modifier:remove_layer("__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-light-anim.png") -- If has two light anim, so remove twice
      if not light then return end

      -- Insert a mask image as static frame
      modifier:insert_mask_layer(
        "__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-anim.png",
        "__disco-science-lite__/graphics/laborat/lab_albedo_anim-mask.png" --[[$GRAPHICS_DIR .. "laborat/lab_albedo_anim-mask.png"]],
        { frame_count = 1, repeat_count = light.frame_count }
      )

      -- It has three same anim layers.
      local anim = modifier:remove_layer("__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-anim.png")
      modifier:remove_layer("__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-anim.png")
      modifier:remove_layer("__krastorio2-assets-ultracube__/buildings/biusart-lab/biusart-lab-anim.png")
      if not anim then return end

      data:extend({
        AnimationHelpers.convert_to_animation_prototype(light, {
          name = "mks-dsl-cube-lab-overlay" --[[$NAME_PREFIX .. "cube-lab-overlay"]],
          filename = "__disco-science-lite__/graphics/laborat/lab_albedo_anim-overlay.png" --[[$GRAPHICS_DIR .. "laborat/lab_albedo_anim-overlay.png"]],
          blend_mode = "additive",
          draw_as_glow = true,
          draw_as_light = false,
        }),
        AnimationHelpers.convert_to_animation_prototype(anim, {
          name = "mks-dsl-cube-lab-companion" --[[$NAME_PREFIX .. "cube-lab-companion"]],
          filename = "__disco-science-lite__/graphics/laborat/lab_albedo_anim-mask.png" --[[$GRAPHICS_DIR .. "laborat/lab_albedo_anim-mask.png"]],
        }),
      })
    end)
  end,
}
