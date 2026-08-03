--- One More Tier by Jakzie
--- https://mods.factorio.com/mod/one-more-tier

--- @type ModSupport
local mod = {}
if not mods["one-more-tier"] then return mod end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

mod.on_data = function ()
  PrototypeLabRegistry.register("omt-lab")
end

mod.on_data_final_fixes = function ()
  AnimationHelpers.modify_on_animation("omt-lab", function (modifier)
    modifier:apply_lab_modifications({
      lab       = "__one-more-tier__/graphics/entity/lab/lab.png",
      lab_light = "__one-more-tier__/graphics/entity/lab/lab-light.png",
    })
  end)
end

return mod
