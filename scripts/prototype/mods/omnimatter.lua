--- Omnimatter mod series by OmnissiahZelos
--- https://mods.factorio.com/user/OmnissiahZelos

if not (mods["omnimatter_compression"] or mods["omnimatter_science"] or mods["omnimatter_energy"]) then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    if mods["omnimatter_compression"] then
      PrototypeColorRegistry.add_prefix("compressed-")
    end

    if mods["omnimatter_science"] and mods["omnimatter_crystal"] then
      PrototypeColorRegistry.set("omni-pack", { 0.83, 0.06, 0.92 })
      PrototypeColorRegistry.set("production-science-pack", { 0.8, 0.41, 0.0 })
    end

    if mods["omnimatter_energy"] then
      PrototypeColorRegistry.set("energy-science-pack", { 0, 0, 0.6 })

      PrototypeLabRegistry.register("omnitor-lab", {
        animation = "mks-dsl-omnitor-lab-overlay" --[[$NAME_PREFIX .. "omnitor-lab-overlay"]],
      })
    end
  end,

  on_data_final_fixes = function ()
    if not mods["omnimatter_energy"] then return end

    AnimationHelpers.modify_on_animation("omnitor-lab", function (modifier)
      local lab_overlay = data.raw["animation"][ "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]] ]

      local light = modifier:remove_layer("__base__/graphics/entity/lab/lab-light.png")
      modifier:freeze_animation()

      if not (light and lab_overlay) then return end
      data:extend({
        {
          type = "animation",
          name = "mks-dsl-omnitor-lab-overlay" --[[$NAME_PREFIX .. "omnitor-lab-overlay"]],
          filename = "__disco-science-lite__/graphics/factorio/aai-burner-lab-overlay.png" --[[$GRAPHICS_DIR .. "factorio/aai-burner-lab-overlay.png"]],
          blend_mode = "additive",
          draw_as_glow = true,
          width = 194,
          height = 174,
          frame_count = 33,
          line_length = 11,
          frame_sequence = lab_overlay and lab_overlay.frame_sequence,
          animation_speed = light.animation_speed,
          shift = light.shift,
          scale = 194 / light.width * 0.5,
        },
      })
    end)
  end,
}
