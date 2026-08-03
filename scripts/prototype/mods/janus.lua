--- Janus by RochX
--- https://mods.factorio.com/mod/janus

--- @type ModSupport
local mod = {}
if not mods["janus"] then return mod end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

mod.on_data = function ()
  PrototypeColorRegistry.set("janus-time-science-pack", { 0.84, 0.39, 0.97 })
end

return mod
