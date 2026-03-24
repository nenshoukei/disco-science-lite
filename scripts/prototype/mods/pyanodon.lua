--- Pyanodons mods by pyanodon
--- https://mods.factorio.com/user/pyanodon

if not (mods["pyalienlife"] or mods["pyfusionenergy"] or mods["pycoalprocessing"]) then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")
local table_merge = require("scripts.shared.utils").table_merge

return {
  on_data = function ()
    if mods["pyalienlife"] then
      PrototypeColorRegistry.set_by_table({
        ["py-science-pack-1"] = { 0.95, 0.48, 0.14 },
        ["py-science-pack-2"] = { 0.90, 0.40, 0.14 },
        ["py-science-pack-3"] = { 0.76, 0.13, 0.10 },
        ["py-science-pack-4"] = { 0.93, 0.37, 0.14 },
      })
    end

    if mods["pyfusionenergy"] then
      PrototypeColorRegistry.set("production-science-pack", { 1.00, 0.27, 0.77 })
    end

    if mods["pycoalprocessing"] then
      -- Overrides the base lab registration
      PrototypeLabRegistry.register("lab", {
        animation = "mks-dsl-pyanodon-lab-overlay" --[[$NAME_PREFIX .. "pyanodon-lab-overlay"]],
      })
    end
  end,

  on_data_final_fixes = function ()
    if not mods["pycoalprocessing"] then return end

    -- The mod only supports the original DiscoScience by `mods["DiscoScience"]` guard.
    -- So, we need to apply the same logic onto the lab prototype.
    -- https://github.com/pyanodon/pycoalprocessing/blob/master/prototypes/buildings/lab.lua#L128
    AnimationHelpers.modify_on_animation("lab", function (modifier)
      local l_layer = modifier:remove_layer("__pycoalprocessinggraphics__/graphics/entity/lab-mk01/l.png")
      local beam_layer = modifier:remove_layer("__pycoalprocessinggraphics__/graphics/entity/lab-mk01/beam.png")
      modifier:remove_layer("__pycoalprocessinggraphics__/graphics/entity/lab-mk01/beam.png") -- Has two beam layers, so remove twice

      modifier:replace_filename(
        "__pycoalprocessinggraphics__/graphics/entity/lab-mk01/raw.png",
        "__pycoalprocessinggraphics__/graphics/entity/lab-mk01/raw-bw.png"
      )

      if not (l_layer and beam_layer) then return end
      data:extend({
        {
          type = "animation",
          name = "mks-dsl-pyanodon-lab-overlay" --[[$NAME_PREFIX .. "pyanodon-lab-overlay"]],
          layers = {
            table_merge(l_layer, {
              filename = "__pycoalprocessinggraphics__/graphics/entity/lab-mk01/l-bw.png",
              draw_as_glow = true,
              draw_as_light = false,
              blend_mode = "additive",
            }),
            table_merge(beam_layer, {
              filename = "__pycoalprocessinggraphics__/graphics/entity/lab-mk01/beam-bw.png",
              draw_as_glow = true,
              draw_as_light = false,
              blend_mode = "additive",
            }),
          },
        },
      })
    end)
  end,
}
