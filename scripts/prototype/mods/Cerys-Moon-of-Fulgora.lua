--- Cerys by thesixthroc
--- https://mods.factorio.com/mod/Cerys-Moon-of-Fulgora

if not mods["Cerys-Moon-of-Fulgora"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")
local table_merge = require("scripts.shared.utils").table_merge

return {
  on_data = function ()
    PrototypeColorRegistry.set("cerysian-science-pack", { 0.65, 1, 0.9 })

    PrototypeLabRegistry.register("cerys-lab", {
      animation = "mks-dsl-cerys-lab-overlay" --[[$NAME_PREFIX .. "cerys-lab-overlay"]],
      companion = "mks-dsl-cerys-lab-companion" --[[$NAME_PREFIX .. "cerys-lab-companion"]],
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("cerys-lab", function (modifier)
      local light = modifier:remove_layer("__base__/graphics/entity/lab/lab-light.png")
      local front_shadow = modifier:remove_layer("__Cerys-Moon-of-Fulgora__/graphics/entity/cerys-lab/cerys-lab-front-shadow.png")
      local front = modifier:remove_layer("__Cerys-Moon-of-Fulgora__/graphics/entity/cerys-lab/cerys-lab-front.png")
      modifier:apply_lab_modifications()
      if not (light and front_shadow and front) then return end

      data:extend({
        table_merge(
          data.raw["animation"][ "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]] ],
          {
            name = "mks-dsl-cerys-lab-overlay" --[[$NAME_PREFIX .. "cerys-lab-overlay"]],
            scale = light.scale,
          }
        ),
        {
          type = "animation",
          name = "mks-dsl-cerys-lab-companion" --[[$NAME_PREFIX .. "cerys-lab-companion"]],
          layers = {
            front_shadow,
            front,

            -- Note: cerys-lab-front.png has a dark texture inside the dome which makes the overlay darker.
            --       To avoid this, we need a dome image without the dark texture, but it is not allowed to
            --       make any derivations from the mod by its license. So, we stay it as-is.
          },
        },
      })
    end)
  end,
}
