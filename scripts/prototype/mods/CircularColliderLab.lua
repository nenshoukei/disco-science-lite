--- Aquilo Overhaul: Circular Collider Lab by Cubickman
--- https://mods.factorio.com/mod/CircularColliderLab

--- @type ModSupport
local mod = {}
if not mods["CircularColliderLab"] then return mod end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

mod.on_data = function ()
  PrototypeLabRegistry.register("circular-collider-lab", {
    animation = "mks-dsl-circular-collider-lab-overlay", --[[$NAME_PREFIX .. "circular-collider-lab-overlay"]]
  })
end

mod.on_data_final_fixes = function ()
  AnimationHelpers.modify_on_animation("circular-collider-lab", function (modifier)
    local emission = modifier:remove_layer("__CircularColliderLab__/graphics/circular-collider-lab-emission.png")
    if not emission then return end

    data:extend({
      AnimationHelpers.convert_to_animation_prototype(emission, {
        name = "mks-dsl-circular-collider-lab-overlay", --[[$NAME_PREFIX .. "circular-collider-lab-overlay"]]
        filename = "__disco-science-lite__/graphics/hurricane/research-center-overlay.png",
        --[[$GRAPHICS_DIR .. "hurricane/research-center-overlay.png"]]
      }),
    })
  end)
end

return mod
