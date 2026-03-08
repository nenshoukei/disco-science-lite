require("scripts.prototype.definitions.animation")

local consts = require("scripts.shared.consts")
local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")

-- Modify all lab prototypes to support colorization
LabPrototypeModifier.modify_target_labs(data.raw["lab"])

-- Single mod-data prototype that stores all external lab registrations.
-- Other mods mutate this table via DiscoScience.prepareLab,
-- and the runtime reads it back through apply_prototype_registrations().
--- @type table<string, LabRegistration>
local lab_registrations = {}
data:extend({
  {
    type = "mod-data",
    name = consts.LAB_REGISTRATIONS_MOD_DATA_NAME,
    data = lab_registrations,
  },
})

--- @class DiscoScienceLabOptions
--- @field animation string? Name of AnimationPrototype to use as an overlay. (Default: the standard lab overlay is used)
--- @field scale integer? Scale of the lab. (Default: `1`)

-- Interface compatible with original DiscoScience
_G.DiscoScience = {
  --- Prepare a lab prototype for disco-science colorization.
  ---
  --- `options` can be used for specifying the lab scale and the overlay animation.
  --- If not passed, the default scale (1) and the standard lab overlay are used.
  --- You can override these settings at runtime by `remote.call()`. See API documents.
  ---
  --- @param lab data.LabPrototype
  --- @param options DiscoScienceLabOptions?
  prepareLab = function (lab, options)
    options = options or {}
    assert(type(lab) == "table" and lab.type == "lab", "DiscoScience.prepareLab: lab must be a LabPrototype table")
    assert(type(lab.name) == "string" and lab.name ~= "", "DiscoScience.prepareLab: lab.name must be a non-empty string")
    assert(type(options) == "table", "DiscoScience.prepareLab: options must be a table")
    assert(options.animation == nil or (type(options.animation) == "string" and options.animation ~= ""),
      "DiscoScience.prepareLab: options.animation must be a non-empty string")
    assert(options.scale == nil or (type(options.scale) == "number" and options.scale > 0),
      "DiscoScience.prepareLab: options.scale must be a positive number")

    LabPrototypeModifier.modify_lab(lab)

    lab_registrations[lab.name] = {
      animation = options.animation,
      scale = options.scale or 1,
    }
  end,
}
