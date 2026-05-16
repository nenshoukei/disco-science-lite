--- Subterranio by TheKingTut
--- https://mods.factorio.com/mod/subterranio

if not mods["subterranio"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["subterranean-science-pack"] = { 0.42, 0.21, 0.37 },
      ["propulsion-science-pack"]   = { 0.90, 0.26, 0.12 },
      ["induction-science-pack"]    = { 0.87, 0.09, 0.24 },
    })
  end,
}
