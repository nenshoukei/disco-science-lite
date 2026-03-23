--- Factorio Space-Age DLC

if not mods["space-age"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["agricultural-science-pack"]    = { 0.80, 0.86, 0.22 },
      ["metallurgic-science-pack"]     = { 0.99, 0.50, 0.04 },
      ["electromagnetic-science-pack"] = { 0.93, 0.17, 0.57 },
      ["cryogenic-science-pack"]       = { 0.16, 0.35, 0.78 },
      ["promethium-science-pack"]      = { 0.10, 0.10, 0.50 },
    })

    PrototypeLabRegistry.register("biolab", {
      animation = "mks-dsl-biolab-overlay" --[[$NAME_PREFIX .. "biolab-overlay"]],
    })

    data:extend({
      {
        type = "animation",
        name = "mks-dsl-biolab-overlay" --[[$NAME_PREFIX .. "biolab-overlay"]],
        filename = "__disco-science-lite__/graphics/factorio/biolab-overlay.png" --[[$GRAPHICS_DIR .. "factorio/biolab-overlay.png"]],
        blend_mode = "additive",
        draw_as_glow = true,
        width = 326,
        height = 362,
        frame_count = 32,
        line_length = 8,
        animation_speed = 0.2,
        scale = 0.5,
        shift = { 0.03125 --[[$1.0 / TILE_SIZE]], -0.203125 --[[$-6.5 / TILE_SIZE]] },
      },
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("biolab", function (anim)
      anim:apply_biolab_modifications()
    end)
  end,
}
