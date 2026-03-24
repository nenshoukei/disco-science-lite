--- Fusion lab by teemu
--- https://mods.factorio.com/mod/fusion-lab

if not mods["fusion-lab"] then return {} end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeLabRegistry.register("fusion-lab", {
      animation = "mks-dsl-fusion-lab-overlay" --[[$NAME_PREFIX .. "fusion-lab-overlay"]],
      companion = "mks-dsl-fusion-lab-companion" --[[$NAME_PREFIX .. "fusion-lab-companion"]],
      is_companion_under_overlay = true,
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("fusion-lab", function (modifier)
      local animation = modifier:get_layer("__fusion-lab__/graphics/entity/fusion-lab/photometric-lab-hr-animation-1.png")
      local emission = modifier:remove_layer("__fusion-lab__/graphics/entity/fusion-lab/photometric-lab-hr-emission-1.png")

      if not (animation and emission) then return end
      data:extend({
        AnimationHelpers.convert_to_animation_prototype(emission, {
          name = "mks-dsl-fusion-lab-overlay" --[[$NAME_PREFIX .. "fusion-lab-overlay"]],
          filenames = {
            "__disco-science-lite__/graphics/hurricane/photometric-lab-hr-overlay-1.png" --[[$GRAPHICS_DIR .. "hurricane/photometric-lab-hr-overlay-1.png"]],
            "__disco-science-lite__/graphics/hurricane/photometric-lab-hr-overlay-2.png" --[[$GRAPHICS_DIR .. "hurricane/photometric-lab-hr-overlay-2.png"]],
          },
        }),

        -- Companion to make the animation sync-ed with the overlay by overriding moving parts.
        AnimationHelpers.convert_to_animation_prototype(animation, {
          name = "mks-dsl-fusion-lab-companion" --[[$NAME_PREFIX .. "fusion-lab-companion"]],
          filenames = {
            "__disco-science-lite__/graphics/hurricane/photometric-lab-hr-override-1.png" --[[$GRAPHICS_DIR .. "hurricane/photometric-lab-hr-override-1.png"]],
            "__disco-science-lite__/graphics/hurricane/photometric-lab-hr-override-2.png" --[[$GRAPHICS_DIR .. "hurricane/photometric-lab-hr-override-2.png"]],
          },
        }),
      })
    end)
  end,
}
