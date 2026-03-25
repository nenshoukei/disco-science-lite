--- Bob's Tech by Bobingabout
--- https://mods.factorio.com/mod/bobtech

if not mods["bobtech"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["bob-advanced-logistic-science-pack"] = { 1.0, 0.2, 0.6 },
      ["bob-science-pack-gold"]              = { 1.0, 0.3, 0.1 },
      ["bob-alien-science-pack"]             = { 1.0, 0.4, 1.0 },
      ["bob-alien-science-pack-blue"]        = { 0.4, 0.6, 1.0 },
      ["bob-alien-science-pack-orange"]      = { 1.0, 0.6, 0.4 },
      ["bob-alien-science-pack-purple"]      = { 0.6, 0.4, 1.0 },
      ["bob-alien-science-pack-yellow"]      = { 1.0, 1.0, 0.4 },
      ["bob-alien-science-pack-green"]       = { 0.4, 1.0, 0.5 },
      ["bob-alien-science-pack-red"]         = { 1.0, 0.5, 0.4 },
    })

    -- Uses the vanilla lab overlay
    PrototypeLabRegistry.register("bob-lab-2")
    PrototypeLabRegistry.register("bob-burner-lab")
    PrototypeLabRegistry.register("bob-lab-alien")
  end,

  on_data_final_fixes = function ()
    local vanilla_lab = data.raw["lab"]["lab"]
    if not (vanilla_lab and vanilla_lab.on_animation) then return end

    AnimationHelpers.modify_on_animation("bob-lab-2", function (modifier)
      --- Copy on_animation from vanilla lab
      modifier.animation.layers = vanilla_lab.on_animation.layers
    end)

    AnimationHelpers.modify_on_animation("bob-burner-lab", function (modifier)
      -- Different shape from the vanilla lab with no light layer
      modifier:freeze_animation()
    end)

    AnimationHelpers.modify_on_animation("bob-lab-alien", function (modifier)
      --- Copy on_animation from vanilla lab
      modifier.animation.layers = vanilla_lab.on_animation.layers
    end)
  end,
}
