--- Janus by Xavier Silva
--- https://mods.factorio.com/mod/janus

if not mods["janus"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set("janus-time-science-pack", { 0.84, 0.39, 0.97 })
  end,
}
