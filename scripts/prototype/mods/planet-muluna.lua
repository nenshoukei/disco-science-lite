--- Muluna, Moon of Nauvis by MeteorSwarm
--- https://mods.factorio.com/mod/planet-muluna

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local table_merge = require("scripts.shared.utils").table_merge

if mods["planet-muluna"] then
  PrototypeColorRegistry.set("interstellar-science-pack", { 0.73, 0.73, 0.73 })

  LabPrototypeModifier.set_layer_removal(
    "__muluna-graphics__/graphics/photometric-lab/photometric-lab-hr-emission-1.png"
  )

  local shared_props = {
    line_length = 8,
    frame_count = 64,
    width = 330,
    height = 390,
    shift = { 0, -0.5 },
    run_mode = "forward-then-backward",
    scale = 0.7,
  }

  data:extend({
    table_merge(shared_props, {
      type = "animation",
      name = "mks-dsl-" --[[$NAME_PREFIX]] .. "cryolab-overlay",
      filename = "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "hurricane/photometric-lab-hr-overlay-1.png",
      blend_mode = "additive",
      draw_as_glow = true,
    }),
    {
      type = "animation",
      name = "mks-dsl-" --[[$NAME_PREFIX]] .. "cryolab-companion",
      layers = {
        table_merge(shared_props, {
          filename = "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "hurricane/photometric-lab-hr-mask-1.png",
        }),
        table_merge(shared_props, {
          filename = "__disco-science-lite__/graphics/" --[[$GRAPHICS_DIR]] .. "hurricane/photometric-lab-hr-red-light-1.png",
          blend_mode = "additive",
          draw_as_glow = true,
        }),
      },
    },
  })

  PrototypeLabRegistry.register("cryolab", {
    animation = "mks-dsl-" --[[$NAME_PREFIX]] .. "cryolab-overlay",
    companion = "mks-dsl-" --[[$NAME_PREFIX]] .. "cryolab-companion",
    is_companion_under_overlay = true,
  })
end
