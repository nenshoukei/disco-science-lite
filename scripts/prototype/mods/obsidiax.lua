--- Planet Obsidiax by Crethor
--- https://mods.factorio.com/mod/obsidiax

if not mods["obsidiax"] then return {} end

local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

return {
  on_data = function ()
    -- Crethor (the mod author) said that the obsidian lab should not be colorized by the general overlay.
    -- https://mods.factorio.com/mod/disco-science-lite/discussion/69e57f3597eaefe0f3c3eab9#post-2
    PrototypeLabRegistry.exclude("obsidiax-lab")
  end,
}
