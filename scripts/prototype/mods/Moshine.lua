--- Moshine by snouz
--- https://mods.factorio.com/mod/Moshine

if not mods["Moshine"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["datacell-empty"]           = { 0.90, 0.90, 0.90 },
      ["datacell-raw-data"]        = { 0.45, 0.78, 0.56 },
      ["datacell-ai-model-data"]   = { 0.51, 0.88, 1.00 },
      ["datacell-equation"]        = { 0.26, 0.46, 0.76 },
      ["datacell-solved-equation"] = { 0.93, 0.88, 0.48 },
    })

    PrototypeLabRegistry.register("neural_computer", {
      animation = "mks-dsl-neural_computer-overlay" --[[$NAME_PREFIX .. "neural_computer-overlay"]],
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("neural_computer", function (modifier)
      local glow_layer = modifier:remove_layer("__Moshine__/graphics/entity/supercomputer/supercomputer_glow.png")
      local light_layer = modifier:remove_layer("__Moshine__/graphics/entity/supercomputer/supercomputer_light.png")
      local anim_layer = modifier:remove_layer("__Moshine__/graphics/entity/supercomputer/supercomputer_anim.png")

      if not (glow_layer and light_layer and anim_layer) then return end
      data:extend({
        {
          type = "animation",
          name = "mks-dsl-neural_computer-overlay" --[[$NAME_PREFIX .. "neural_computer-overlay"]],
          layers = {
            glow_layer,
            light_layer,
            anim_layer,
          },
        },
      })
    end)
  end,
}
