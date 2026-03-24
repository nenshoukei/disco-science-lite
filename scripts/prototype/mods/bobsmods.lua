--- Bob's Tech by Bobingabout
--- https://mods.factorio.com/mod/bobtech

if not mods["bobtech"] then return {} end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    -- Ingredients colors are registered by the mod itself by using the remote interface.

    -- Uses the vanilla lab overlay
    PrototypeLabRegistry.register("bob-lab-2")
    PrototypeLabRegistry.register("bob-burner-lab")
    PrototypeLabRegistry.register("bob-lab-alien")
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("bob-lab-2", function (modifier)
      modifier:remove_layer("__bobtech__/graphics/entity/lab/lab2-light.png")
      modifier:freeze_animation()
    end)

    AnimationHelpers.modify_on_animation("bob-burner-lab", function (modifier)
      -- No light layer
      modifier:freeze_animation()
    end)

    AnimationHelpers.modify_on_animation("bob-lab-alien", function (modifier)
      modifier:remove_layer("__bobtech__/graphics/entity/lab/lab-alien-light.png")
      modifier:freeze_animation()
    end)
  end,
}
