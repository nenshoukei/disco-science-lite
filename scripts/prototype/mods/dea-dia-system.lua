--- 🌐Dea Dia System by Frontrider
--- https://mods.factorio.com/mod/dea-dia-system

if not mods["dea-dia-system"] then return {} end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    -- Dea Dia System uses Quality Glassware mod for science pack icons, whose color will be registered by quality_glassware.lua

    PrototypeLabRegistry.register("thermodynamics-lab", {
      animation = "mks-dsl-thermodynamics-lab-overlay" --[[$NAME_PREFIX .. "thermodynamics-lab-overlay"]],
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("thermodynamics-lab", function (modifier)
      local emission = modifier:remove_layer("__dea-dia-system__/graphics/entity/thermodynamics-laboratory/thermodynamics-laboratory-emission.png")

      if not emission then return end
      data:extend({
        {
          type            = "animation",
          name            = "mks-dsl-thermodynamics-lab-overlay", --[[$NAME_PREFIX .. "thermodynamics-lab-overlay"]]
          filename        = "__disco-science-lite__/graphics/hurricane/arc-furnace-hr-overlay.png", --[[$GRAPHICS_DIR .. "hurricane/arc-furnace-hr-overlay.png"]]
          frame_count     = 50,
          line_length     = 8,
          width           = 320,
          height          = 320,
          animation_speed = emission.animation_speed,
          scale           = 320 / emission.width * 0.5,
          draw_as_glow    = true,
          blend_mode      = "additive",
        },
      })
    end)
  end,
}
