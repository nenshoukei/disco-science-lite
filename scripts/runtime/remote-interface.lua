--- @class RemoteInterface
local RemoteInterface = {}

--- @class DiscoScienceRemote
local DiscoScienceRemote = {}
RemoteInterface.functions = DiscoScienceRemote

--- @type LabRegistry|nil
local lab_registry = nil
--- @type ColorRegistry|nil
local color_registry = nil

--- @type {fname: string, args: any[]}[]
local pending_calls = {}

--- @param ds_storage DiscoScienceStorage
function RemoteInterface.bind_storage(ds_storage)
  lab_registry = ds_storage.lab_registry
  color_registry = ds_storage.color_registry
  for i = 1, #pending_calls do
    local call = pending_calls[i]
    RemoteInterface.functions[call.fname](table.unpack(call.args))
  end
  pending_calls = {}
end

function DiscoScienceRemote.registerLab(lab_name, settings)
  assert(type(lab_name) == "string" and lab_name ~= "", "DiscoScience.registerLab: lab_name must be a non-empty string")
  assert(type(settings) == "table", "DiscoScience.registerLab: settings must be a table")
  assert(settings.animation == nil or (type(settings.animation) == "string" and settings.animation ~= ""),
    "DiscoScience.registerLab: settings.animation must be a non-empty string")
  assert(settings.scale == nil or (type(settings.scale) == "number" and settings.scale > 0),
    "DiscoScience.registerLab: settings.scale must be a positive number")
  if not lab_registry then
    pending_calls[#pending_calls + 1] = { fname = "registerLab", args = { lab_name, settings } }
    return
  end
  lab_registry:register(lab_name, {
    animation = settings.animation,
    scale = settings.scale,
  })
end

function DiscoScienceRemote.setLabScale(lab_name, scale)
  assert(type(lab_name) == "string" and lab_name ~= "", "DiscoScience.setLabScale: lab_name must be a non-empty string")
  assert(type(scale) == "number" and scale > 0, "DiscoScience.setLabScale: scale must be a positive number")
  if not lab_registry then
    pending_calls[#pending_calls + 1] = { fname = "setLabScale", args = { lab_name, scale } }
    return
  end
  lab_registry:set_scale(lab_name, scale)
end

function DiscoScienceRemote.setIngredientColor(item_name, color)
  assert(type(item_name) == "string" and item_name ~= "",
    "DiscoScience.setIngredientColor: item_name must be a non-empty string")
  assert(type(color) == "table" and (
    (type(color[1]) == "number" and type(color[2]) == "number" and type(color[3]) == "number") or
    (type(color.r) == "number" and type(color.g) == "number" and type(color.b) == "number")
  ), "DiscoScience.setIngredientColor: color must be a Color table")
  if not color_registry then
    pending_calls[#pending_calls + 1] = { fname = "setIngredientColor", args = { item_name, color } }
    return
  end
  color_registry:set_ingredient_color(item_name, color)
end

function DiscoScienceRemote.getIngredientColor(item_name)
  if not color_registry then return end
  assert(type(item_name) == "string" and item_name ~= "",
    "DiscoScience.getIngredientColor: item_name must be a non-empty string")
  return color_registry:get_ingredient_color(item_name)
end

return RemoteInterface
