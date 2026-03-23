--- 🌐Planet Rubia by Loup&Snoop
--- https://mods.factorio.com/mod/rubia

if not mods["rubia"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["biorecycling-science-pack"]    = { 0.62, 0.42, 0.38 },
      ["rubia-biofusion-science-pack"] = { 1.00, 0.98, 0.38 },
    })
  end,
}
