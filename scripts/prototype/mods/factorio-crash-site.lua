--- Factorio crash site (and legacy items) by MFerrari
--- https://mods.factorio.com/mod/factorio-crash-site
--- Crash Site by atanvarno
--- https://mods.factorio.com/mod/atan-crash-site
--- Crash Site Settings by Kryzeth
--- https://mods.factorio.com/mod/kry-crash-site-settings

--- @type ModSupport
local mod = {}
if not mods["factorio-crash-site"] then return mod end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

mod.on_data = function ()
  PrototypeLabRegistry.register("crash-site-lab-repaired", {
    animation = "mks-dsl-crash-site-lab-repaired-overlay", --[[$NAME_PREFIX .. "crash-site-lab-repaired-overlay"]]
  })

  if mods["atan-crash-site"] then
    PrototypeLabRegistry.register("crash-site-lab", {
      animation = "mks-dsl-crash-site-lab-repaired-overlay", --[[$NAME_PREFIX .. "crash-site-lab-repaired-overlay"]]
    })
  end

  if mods["kry-crash-site-settings"] then
    PrototypeLabRegistry.register("crash-site-kry-lab", {
      animation = "mks-dsl-crash-site-lab-repaired-overlay", --[[$NAME_PREFIX .. "crash-site-lab-repaired-overlay"]]
    })
  end
end

mod.on_data_final_fixes = function ()
  AnimationHelpers.modify_on_animation("crash-site-lab-repaired", function (modifier)
    local beam = modifier:remove_layer("__factorio-crash-site__/graphics/entity/crash-site-lab/hr-crash-site-lab-repaired-beams.png")
    if not beam then return end

    data:extend({
      AnimationHelpers.convert_to_animation_prototype(beam, {
        name = "mks-dsl-crash-site-lab-repaired-overlay", --[[$NAME_PREFIX .. "crash-site-lab-repaired-overlay"]]
        blend_mode = "additive",
        draw_as_glow = true,
      }),
    })
  end)

  if mods["atan-crash-site"] then
    AnimationHelpers.modify_on_animation("crash-site-lab", function (modifier)
      modifier:remove_layer("__factorio-crash-site__/graphics/entity/crash-site-lab/hr-crash-site-lab-repaired-beams.png")
    end)
  end

  if mods["kry-crash-site-settings"] then
    AnimationHelpers.modify_on_animation("crash-site-kry-lab", function (modifier)
      modifier:remove_layer("__factorio-crash-site__/graphics/entity/crash-site-lab/hr-crash-site-lab-repaired-beams.png")
    end)
  end
end

return mod
