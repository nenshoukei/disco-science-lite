--- Lab-O-Matic by Stargateur
--- https://mods.factorio.com/mod/LabOMatic

if not mods["LabOMatic"] then return {} end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeLabRegistry.register("labomatic", {
      animation = "mks-dsl-labomatic-overlay" --[[$NAME_PREFIX .. "labomatic-overlay"]],
      companion = "mks-dsl-labomatic-companion" --[[$NAME_PREFIX .. "labomatic-companion"]],
      is_companion_under_overlay = true,
    })
  end,

  on_data_final_fixes = function ()
    local hd = settings.startup["labomatic-hd"].value and "_x4" or ""

    AnimationHelpers.modify_on_animation("labomatic", function (modifier)
      local light = modifier:remove_layer("__LabOMatic__/graphics/lab_light_anim" .. hd .. ".png")
      if not light then return end

      -- Insert a mask image as static frame
      modifier:insert_mask_layer(
        "__LabOMatic__/graphics/lab_albedo_anim" .. hd .. ".png",
        "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "laborat/lab_albedo_anim" .. hd .. "-mask.png",
        { frame_count = 1, repeat_count = light.frame_count }
      )
      local anim = modifier:remove_layer("__LabOMatic__/graphics/lab_albedo_anim" .. hd .. ".png")
      if not anim then return end

      data:extend({
        AnimationHelpers.convert_to_animation_prototype(light, {
          name = "mks-dsl-labomatic-overlay" --[[$NAME_PREFIX .. "labomatic-overlay"]],
          filename = "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "laborat/lab_albedo_anim" .. hd .. "-overlay.png",
          blend_mode = "additive",
          draw_as_glow = true,
          frame_count = 1,
        }),
        AnimationHelpers.convert_to_animation_prototype(anim, {
          name = "mks-dsl-labomatic-companion" --[[$NAME_PREFIX .. "labomatic-companion"]],
          filename = "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "laborat/lab_albedo_anim" .. hd .. "-mask.png",
        }),
      })
    end)
  end,
}
