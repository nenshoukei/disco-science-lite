--- Panglia Planet by snouz
--- https://mods.factorio.com/mod/panglia_planet

if not mods["panglia_planet"] then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["datacell-dna-raw"]       = { 0.17, 0.16, 0.15 },
      ["datacell-dna-sequenced"] = { 0.97, 0.13, 0.14 },
    })
  end,
}
