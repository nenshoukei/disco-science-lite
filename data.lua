require("scripts.prototype.definitions.animation")

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")

-- Modify target lab prototypes
LabPrototypeModifier.modify_target_labs(data.raw["lab"])

-- Interface compatible with original DiscoScience
_G.DiscoScience = {
  prepareLab = LabPrototypeModifier.modify_lab,
}
