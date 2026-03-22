--- 🌐Planet Rubia by Loup&Snoop
--- https://mods.factorio.com/mod/rubia

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

if mods["rubia"] then
  PrototypeColorRegistry.set_by_table({
    ["biorecycling-science-pack"]    = { 0.62, 0.42, 0.38 },
    ["rubia-biofusion-science-pack"] = { 1.00, 0.98, 0.38 },
  })
end
