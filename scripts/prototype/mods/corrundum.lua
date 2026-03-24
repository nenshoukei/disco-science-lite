--- 🌐Corrundum by AnotherZach
--- https://mods.factorio.com/mod/corrundum

if not mods["corrundum"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")
local table_merge = require("scripts.shared.utils").table_merge

--- @param lab_overlay data.AnimationPrototype
--- @param frame_count integer
local function make_lab_frame_sequence(lab_overlay, frame_count)
  local lab_frame_sequence = lab_overlay.frame_sequence
  if not lab_frame_sequence then
    -- Make a full frame_sequence for the lab overlay
    lab_frame_sequence = {}
    for i = 1, lab_overlay.frame_count do
      lab_frame_sequence[i] = i
    end
  end

  -- Repeat the lab overlay's frame_sequence until it fits to frame_count.
  local repeated_frame_sequence = {}
  local n_lab_frame_sequence = #lab_frame_sequence
  local index = 1
  for i = 1, frame_count do
    repeated_frame_sequence[i] = lab_frame_sequence[index]
    index = index == n_lab_frame_sequence and 1 or (index + 1)
  end

  return repeated_frame_sequence
end

return {
  on_data = function ()
    PrototypeColorRegistry.set("electrochemical-science-pack", { 0.91, 0.71, 0.27 })

    PrototypeLabRegistry.register("pressure-lab", {
      animation = "mks-dsl-pressure-lab-overlay" --[[$NAME_PREFIX .. "pressure-lab-overlay"]],
      companion = "mks-dsl-pressure-lab-companion" --[[$NAME_PREFIX .. "pressure-lab-companion"]],
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("pressure-lab", function (modifier)
      local lab_overlay = data.raw["animation"][ "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]] ]
      local lab_mask = modifier:get_layer("__corrundum__/graphics/entity/chem-lab-on-mask.png")
      local smoke_outer = modifier:remove_layer("__corrundum__/graphics/entity/chemical-plant-smoke-outer-blue.png")
      local smoke_inner = modifier:remove_layer("__corrundum__/graphics/entity/chemical-plant-smoke-inner-blue.png")
      modifier:remove_layer("__corrundum__/graphics/entity/lab-light-three-times-frames-no-change.png")
      modifier:freeze_animation()

      if not (lab_overlay and lab_mask and smoke_outer and smoke_inner) then return end

      local frame_count = smoke_outer.frame_count --[[@as integer]]
      local frame_sequence = make_lab_frame_sequence(lab_overlay, frame_count)

      data:extend({
        {
          type = "animation",
          name = "mks-dsl-pressure-lab-overlay" --[[$NAME_PREFIX .. "pressure-lab-overlay"]],
          layers = {
            AnimationHelpers.convert_to_animation(lab_overlay, {
              frame_sequence = frame_sequence,
              frame_count = frame_count,
            }),
            table_merge(smoke_outer, {
              filename = "__disco-science-lite__/graphics/corrundum/chemical-plant-smoke-outer-grayscaled.png"
              --[[$GRAPHICS_DIR .. "corrundum/chemical-plant-smoke-outer-grayscaled.png"]],
            }),
            table_merge(smoke_inner, {
              filename = "__disco-science-lite__/graphics/corrundum/chemical-plant-smoke-inner-grayscaled.png"
              --[[$GRAPHICS_DIR .. "corrundum/chemical-plant-smoke-inner-grayscaled.png"]],
            }),
          },
        },
        AnimationHelpers.convert_to_animation_prototype(lab_mask, {
          name = "mks-dsl-pressure-lab-companion" --[[$NAME_PREFIX .. "pressure-lab-companion"]],
        }),
      })
    end)
  end,
}
