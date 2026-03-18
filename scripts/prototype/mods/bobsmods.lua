--- Bob's Tech by Bobingabout
--- https://mods.factorio.com/mod/bobtech
--- Artisanal Reskins: Bob's Mods
--- https://mods.factorio.com/mod/reskins-bobs

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

if mods["bobtech"] then
  -- Ingredients colors are registered by the mod itself by using the remote interface.

  -- Change the on_animation to the vanilla lab (grayscale) for colorization.
  LabPrototypeModifier.set_filename_replacement(
    "__bobtech__/graphics/entity/lab/lab2.png",
    "__base__/graphics/entity/lab/lab.png"
  )
  LabPrototypeModifier.set_layer_removal(
    "__bobtech__/graphics/entity/lab/lab2-light.png"
  )
  LabPrototypeModifier.set_filename_replacement(
    "__bobtech__/graphics/entity/lab/lab-red.png",
    "__base__/graphics/entity/lab/lab.png"
  )
  LabPrototypeModifier.set_filename_replacement(
    "__bobtech__/graphics/entity/lab/lab-alien.png",
    "__base__/graphics/entity/lab/lab.png"
  )
  LabPrototypeModifier.set_layer_removal(
    "__bobtech__/graphics/entity/lab/lab-alien-light.png"
  )

  PrototypeLabRegistry.register("bob-lab-2", {
    animation = "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]],
  })
  PrototypeLabRegistry.register("bob-burner-lab", {
    animation = "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]],
  })
  PrototypeLabRegistry.register("bob-lab-alien", {
    animation = "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]],
  })
end

if mods["reskins-bobs"] then
  LabPrototypeModifier.set_filename_replacement(
    "__reskins-bobs__/graphics/entity/technology/lab/bob-lab-2.png",
    "__base__/graphics/entity/lab/lab.png"
  )
  LabPrototypeModifier.set_filename_replacement(
    "__reskins-bobs__/graphics/entity/technology/lab/bob-lab-alien.png",
    "__base__/graphics/entity/lab/lab.png"
  )
end
