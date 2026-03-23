--- 🌐Metal and Stars by Alex Boucher
--- https://mods.factorio.com/mod/metal-and-stars

if not mods["metal-and-stars"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["quantum-science-pack"] = { 1.00, 0.34, 0.91 },
      ["anomaly-science-pack"] = { 0.23, 0.18, 0.98 },
      ["nanite-science-pack"]  = { 0.89, 0.89, 0.89 },
      ["ring-science-pack"]    = { 0.94, 0.88, 0.39 },
    })

    PrototypeLabRegistry.register("microgravity-lab", {
      animation = "mks-dsl-microgravity-lab-overlay" --[[$NAME_PREFIX .. "microgravity-lab-overlay"]],
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("microgravity-lab", function (anim)
      local emission = anim:remove_layer("__metal-and-stars-graphics__/graphics/entity/particle-accelerator/particle-accelerator-hr-animation-emission.png")

      if not emission then return end
      data:extend({
        AnimationHelpers.convert_to_animation_prototype(emission, {
          name = "mks-dsl-microgravity-lab-overlay" --[[$NAME_PREFIX .. "microgravity-lab-overlay"]],
          stripes = {
            {
              filename = "__disco-science-lite__/graphics/hurricane/fusion-reactor-hr-overlay.png"
              --[[$GRAPHICS_DIR .. "hurricane/fusion-reactor-hr-overlay.png"]],
              width_in_frames = 8,
              height_in_frames = 8,
            },
          },
        }),
      })
    end)
  end,
}
