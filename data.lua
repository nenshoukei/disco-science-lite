require("scripts.prototype.definitions.animation")

local consts = require("scripts.shared.consts")
local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")

-- Modify all lab prototypes to support colorization
LabPrototypeModifier.modify_target_labs(data.raw["lab"])

-- Single mod-data prototype that stores all external lab registrations.
-- Other mods mutate this table via DiscoScience.prepareLab / registerLab,
-- and the runtime reads it back through apply_prototype_registrations().
--- @type table<string, AnyBasic>
local lab_registrations = {}
data:extend({
  {
    type = "mod-data",
    name = consts.LAB_REGISTRATIONS_MOD_DATA_NAME,
    data = lab_registrations,
  },
})

--- @class DiscoScienceLabOptions
--- @field animation string Name of AnimationPrototype to use as an overlay.
--- @field scale integer? Scale of the lab. (Default: `1`)

-- Interface compatible with original DiscoScience
_G.DiscoScience = {
  --- Prepare a lab prototype for disco-science colorization.
  ---
  --- Use this together with remote.call("DiscoScience", "addTargetLab", ...) at runtime
  --- to specify the overlay animation. For a single-step registration, use registerLab instead.
  ---
  --- @param lab data.LabPrototype
  prepareLab = function(lab)
    LabPrototypeModifier.modify_lab(lab)
    -- Store a marker so runtime can enumerate all prepared labs if needed.
    -- No animation is set here; use addTargetLab remote call to specify one.
    lab_registrations[lab.name] = {}
  end,

  --- Register a lab for disco-science colorization in a single prototype-stage call.
  ---
  --- No runtime remote.call needed. The overlay animation and scale are stored
  --- in a mod-data prototype and picked up automatically at runtime.
  ---
  --- @param lab data.LabPrototype
  --- @param options DiscoScienceLabOptions
  registerLab = function(lab, options)
    LabPrototypeModifier.modify_lab(lab)
    lab_registrations[lab.name] = {
      animation = options.animation,
      scale = options.scale or 1,
    }
  end,
}
