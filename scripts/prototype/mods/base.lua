--- Factorio base

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["automation-science-pack"] = { 0.91, 0.16, 0.20 },
      ["logistic-science-pack"]   = { 0.29, 0.97, 0.31 },
      ["chemical-science-pack"]   = { 0.28, 0.93, 0.95 },
      ["production-science-pack"] = { 0.83, 0.06, 0.92 },
      ["military-science-pack"]   = { 0.58, 0.61, 0.68 },
      ["utility-science-pack"]    = { 0.96, 0.93, 0.30 },
      ["space-science-pack"]      = { 1.00, 1.00, 1.00 },
    })

    PrototypeLabRegistry.register("lab")

    -- Mark the vanilla lab on_animation so that we can detect on_animation replaced by mods.
    local lab = data.raw.lab["lab"]
    if lab and lab.on_animation then
      lab.on_animation["_dsl_is_original"] = true
    end
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("lab", function (modifier)
      -- Applies modifications only if the on_animation is the original one.
      if modifier.animation["_dsl_is_original"] then
        modifier:apply_lab_modifications()
      end
    end)
  end,
}
