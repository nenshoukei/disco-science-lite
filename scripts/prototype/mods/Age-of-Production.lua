--- Age of Production by AndreusAxolotl
--- https://mods.factorio.com/mod/Age-of-Production

if not mods["Age-of-Production"] then return {} end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeLabRegistry.register("aop-quantum-computer", {
      animation = "mks-dsl-aop-quantum-computer-overlay" --[[$NAME_PREFIX .. "aop-quantum-computer-overlay"]],
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("aop-quantum-computer", function (anim)
      local emission = anim:remove_layer("__Age-of-Production-Graphics__/graphics/entity/quantum-computer/quantum-computer-hr-emission-1.png")

      if not emission then return end
      data:extend({
        AnimationHelpers.convert_to_animation_prototype(emission, {
          name = "mks-dsl-aop-quantum-computer-overlay" --[[$NAME_PREFIX .. "aop-quantum-computer-overlay"]],
          filename = "__disco-science-lite__/graphics/hurricane/fusion-reactor-hr-overlay.png"
          --[[$GRAPHICS_DIR .. "hurricane/fusion-reactor-hr-overlay.png"]],
        }),
      })
    end)
  end,
}
