--- Muluna, Moon of Nauvis by MeteorSwarm
--- https://mods.factorio.com/mod/planet-muluna

if not mods["planet-muluna"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeColorRegistry.set("interstellar-science-pack", { 0.73, 0.73, 0.73 })

    PrototypeLabRegistry.register("cryolab", {
      animation = "mks-dsl-cryolab-overlay" --[[$NAME_PREFIX .. "cryolab-overlay"]],
      companion = "mks-dsl-cryolab-companion" --[[$NAME_PREFIX .. "cryolab-companion"]],
      is_companion_under_overlay = true,
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("cryolab", function (anim)
      local emission = anim:remove_layer("__muluna-graphics__/graphics/photometric-lab/photometric-lab-hr-emission-1.png")
      local animation = anim:get_layer("__muluna-graphics__/graphics/photometric-lab/photometric-lab-hr-animation-1.png")
      if not (emission and animation) then return end

      data:extend({
        AnimationHelpers.convert_to_animation_prototype(emission, {
          name = "mks-dsl-cryolab-overlay" --[[$NAME_PREFIX .. "cryolab-overlay"]],
          filename = "__disco-science-lite__/graphics/hurricane/photometric-lab-hr-overlay-1.png"
          --[[$GRAPHICS_DIR .. "hurricane/photometric-lab-hr-overlay-1.png"]],
          animation_speed = 1,
        }),

        -- Companion to make the animation sync-ed with the overlay by overriding moving parts.
        AnimationHelpers.convert_to_animation_prototype(animation, {
          name = "mks-dsl-cryolab-companion" --[[$NAME_PREFIX .. "cryolab-companion"]],
          filename = "__disco-science-lite__/graphics/hurricane/photometric-lab-hr-override-1.png"
          --[[$GRAPHICS_DIR .. "hurricane/photometric-lab-hr-override-1.png"]],
          animation_speed = 1,
        }),
      })
    end)
  end,
}
