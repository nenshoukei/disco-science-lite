--- Shattered Planet by CPU_BlackHeart
--- https://mods.factorio.com/mod/skewer_shattered_planet

if not mods["skewer_shattered_planet"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["ske_heu_science_pack"] = { 0.69, 0.16, 0.56 },
      ["ske_hep_science_pack"] = { 0.34, 0.96, 0.97 },
      ["ske_hea_science_pack"] = { 0.01, 0.35, 0.92 },
      ["ske_hec_science_pack"] = { 0.21, 0.3, 0.49 },
      ["ske_hef_science_pack"] = { 0.38, 0.29, 0.92 },
      ["ske_antimatter_cell"]  = { 0.88, 0.19, 0.42 },
    })

    PrototypeLabRegistry.register("pearl_realizer", {
      animation = "mks-dsl-pearl-realizer-overlay" --[[$NAME_PREFIX .. "pearl-realizer-overlay"]],
      companion = "mks-dsl-pearl-realizer-companion" --[[$NAME_PREFIX .. "pearl-realizer-companion"]],
      is_companion_under_overlay = true,
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("pearl_realizer", function (modifier)
      local anim = modifier:remove_layer("__space-exploration-graphics-4__/graphics/entity/gravimetrics-laboratory/gravimetrics-laboratory.png")
      local tint = modifier:remove_layer("__space-exploration-graphics-4__/graphics/entity/gravimetrics-laboratory/gravimetrics-laboratory-tint.png")
      if not anim or not tint then return end

      data:extend({
        AnimationHelpers.convert_to_animation_prototype(tint, {
          name = "mks-dsl-pearl-realizer-overlay" --[[$NAME_PREFIX .. "pearl-realizer-overlay"]],
        }),
        AnimationHelpers.convert_to_animation_prototype(anim, {
          name = "mks-dsl-pearl-realizer-companion" --[[$NAME_PREFIX .. "pearl-realizer-companion"]],
        }),
      })
    end)
  end,
}
