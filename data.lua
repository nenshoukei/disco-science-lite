require("scripts.prototype.definitions.animation")
require("scripts.prototype.definitions.mod-data")

local all_mods = require("scripts.prototype.mods._all")
for i = 1, #all_mods do
  local mod = all_mods[i]
  if mod.on_data then mod.on_data() end
end

require("scripts.prototype.disco-science-interface")
