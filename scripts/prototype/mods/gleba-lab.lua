--- Gleba Lab by LordMiguel
--- https://mods.factorio.com/mod/gleba-lab

if not mods["gleba-lab"] then return {} end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeLabRegistry.exclude("glebalab")
    PrototypeLabRegistry.register("glebalab", {
      animation = "mks-dsl-glebalab-overlay" --[[$NAME_PREFIX .. "glebalab-overlay"]],
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("glebalab", function (modifier)
      local lights = modifier:remove_layer("__gleba-lab__/graphics/entity/GlebaLabLights.png")
      if not lights then return end

      data:extend({
        {
          type = "animation",
          name = "mks-dsl-glebalab-overlay" --[[$NAME_PREFIX .. "glebalab-overlay"]],
          filename = "__disco-science-lite__/graphics/factorio/biolab-overlay.png" --[[$GRAPHICS_DIR .. "factorio/biolab-overlay.png"]],
          blend_mode = "additive",
          draw_as_glow = true,
          width = 326,
          height = 362,
          frame_count = 32,
          line_length = 8,
          animation_speed = 0.2,
          scale = 0.5,
          shift = lights.shift,
        },
      })
    end)
  end,
}
