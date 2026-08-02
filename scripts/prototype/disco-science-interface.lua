local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

if _G.DiscoScience then
  return _G.DiscoScience
end

--- @type DiscoScience.Interface
local DiscoScienceInterface = {
  isLite = true,

  excludeLab = function (lab)
    local lab_name = type(lab) == "string" and lab or (type(lab) == "table" and lab.name)
    assert(type(lab_name) == "string" and lab_name ~= "", "DiscoScience.excludeLab: lab must be a LabPrototype table or a non-empty string")

    PrototypeLabRegistry.exclude(lab_name)
  end,

  prepareLab = function (lab, options)
    options = options or {}
    assert(type(lab) == "table" and lab.type == "lab", "DiscoScience.prepareLab: lab must be a LabPrototype table")
    assert(type(lab.name) == "string" and lab.name ~= "", "DiscoScience.prepareLab: lab.name must be a non-empty string")
    assert(type(options) == "table", "DiscoScience.prepareLab: options must be a table")
    assert(
      options.animation == nil or (type(options.animation) == "string" and options.animation ~= ""),
      "DiscoScience.prepareLab: options.animation must be a non-empty string"
    )

    PrototypeLabRegistry.register(lab.name, {
      animation = options.animation,
    })
  end,
}
_G.DiscoScience = DiscoScienceInterface

return DiscoScienceInterface
