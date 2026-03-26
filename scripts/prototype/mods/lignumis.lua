--- Lignumis by cackling fiend
--- https://mods.factorio.com/mod/lignumis

if not mods["lignumis"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["steam-science-pack"] = { 0.75, 0.88, 1.00 },
      ["wood-science-pack"]  = { 0.62, 0.37, 0.28 },
    })

    PrototypeLabRegistry.register("wood-lab")
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("wood-lab", function (modifier)
      modifier:remove_layer("__lignumis-assets__/entity/wood-lab/wood-lab-light.png")
      modifier:freeze_animation()
    end)
  end,
}
