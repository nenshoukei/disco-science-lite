--- AAI Industry by Earendel
--- https://mods.factorio.com/mod/aai-industry

if not mods["aai-industry"] then return {} end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeLabRegistry.register("burner-lab", {
      animation = "mks-dsl-burner-lab-overlay" --[[$NAME_PREFIX .. "burner-lab-overlay"]],
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("burner-lab", function (modifier)
      local lab_overlay = data.raw["animation"][ "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]] ]

      local light = modifier:remove_layer("__aai-industry__/graphics/entity/burner-lab/burner-lab-light.png")
      modifier:freeze_animation()

      if not (light and lab_overlay) then return end
      data:extend({
        AnimationHelpers.convert_to_animation_prototype(light, {
          name = "mks-dsl-burner-lab-overlay" --[[$NAME_PREFIX .. "burner-lab-overlay"]],
          filename = "__disco-science-lite__/graphics/factorio/aai-burner-lab-overlay.png" --[[$GRAPHICS_DIR .. "factorio/aai-burner-lab-overlay.png"]],
          blend_mode = "additive",
          draw_as_glow = true,
          frame_sequence = lab_overlay and lab_overlay.frame_sequence,
        }),
      })
    end)
  end,
}
