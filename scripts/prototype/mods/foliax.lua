--- Planet Foliax by Crethor
--- https://mods.factorio.com/mod/foliax

if not mods["foliax"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["foliax-research-transportation"] = { 0.80, 0.33, 0.49 },
      ["foliax-research-machine"]        = { 0.80, 0.49, 0.33 },
      ["foliax-research-biology"]        = { 0.60, 0.78, 0.35 },
      ["foliax-research-power"]          = { 0.28, 0.77, 0.78 },
      ["foliax-research-optimization"]   = { 0.77, 0.35, 0.78 },
      ["foliax-research-violence"]       = { 0.58, 0.58, 0.58 },
    })

    PrototypeLabRegistry.register("foliax-burner-biolab", {
      animation = "mks-dsl-biolab-overlay" --[[$NAME_PREFIX .. "biolab-overlay"]],
    })
    PrototypeLabRegistry.register("foliax-burner-biolab-mk2", {
      animation = "mks-dsl-biolab-overlay" --[[$NAME_PREFIX .. "biolab-overlay"]],
    })
  end,

  on_data_final_fixes = function ()
    AnimationHelpers.modify_on_animation("foliax-burner-biolab", function (modifier)
      modifier:apply_biolab_modifications()
    end)
    AnimationHelpers.modify_on_animation("foliax-burner-biolab-mk2", function (modifier)
      modifier:apply_biolab_modifications()
    end)
  end,
}
