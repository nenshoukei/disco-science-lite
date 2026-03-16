--- Lab-O-Matic by Stargateur
--- https://mods.factorio.com/mod/LabOMatic

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

if mods["LabOMatic"] then
  local hd = settings.startup["labomatic-hd"].value --[[@as boolean]]
  local animation

  if hd then
    animation = "mks-dsl-" --[[$NAME_PREFIX]] .. "labomatic-overlay"

    LabPrototypeModifier.set_filename_replacement(
      "__LabOMatic__/graphics/lab_albedo_anim_x4.png",
      "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "laborat/lab_albedo_anim_x4-masked.png"
    )
    LabPrototypeModifier.set_filename_removal(
      "__LabOMatic__/graphics/lab_light_anim_x4.png"
    )

    data:extend({
      {
        type = "animation",
        name = animation,
        filename = "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "laborat/lab_albedo_anim_x4-overlay.png",
        blend_mode = "additive",
        draw_as_glow = true,
        width = 600,
        height = 600,
        frame_count = 1,
        shift = { 0, -0.05 },
        scale = 0.21325,
      },
    })
  else
    animation = "mks-dsl-" --[[$NAME_PREFIX]] .. "LabOMatic-x4-overlay"

    LabPrototypeModifier.set_filename_replacement(
      "__LabOMatic__/graphics/lab_albedo_anim.png",
      "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "laborat/lab_albedo_anim-masked.png"
    )
    LabPrototypeModifier.set_filename_removal(
      "__LabOMatic__/graphics/lab_light_anim.png"
    )

    data:extend({
      {
        type = "animation",
        name = animation,
        filename = "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "laborat/lab_albedo_anim-overlay.png",
        blend_mode = "additive",
        draw_as_glow = true,
        width = 150,
        height = 150,
        frame_count = 1,
        shift = { 0, -0.05 },
        scale = 0.853,
      },
    })
  end

  PrototypeLabRegistry.register("labomatic", {
    animation = animation,
  })
end
