--- Voidcraft by S6X
--- https://mods.factorio.com/mod/Voidcraft

if not mods["Voidcraft"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["void-science-pack"]      = { 0.97, 0.07, 1.00 },
      ["esoteric-science-pack"]  = { 0.28, 0.06, 1.00 },
      ["celestial-science-pack"] = { 0.17, 0.35, 0.88 },
    })
  end,
}
