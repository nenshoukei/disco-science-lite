--- Planetaris: Tellus by Syen
--- https://mods.factorio.com/mod/planetaris-tellus

if not mods["planetaris-tellus"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["planetaris-bioengineering-science-pack"] = { 0.91, 0.75, 0.44 },
      ["planetaris-pathological-science-pack"]   = { 0.86, 0.31, 0.25 },
    })
  end,
}
