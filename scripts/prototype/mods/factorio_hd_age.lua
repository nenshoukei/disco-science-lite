--- Factorio HD Age mod series by Ingo_Igel
--- https://mods.factorio.com/mod/factorio_hd_age_modpack

local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")

if mods["factorio_hd_age_base_game_production"] then
  LabPrototypeModifier.set_layer_removal(
    "__factorio_hd_age_base_game_production__/data/base/graphics/entity/lab/lab-light.png"
  )
end

if mods["factorio_hd_age_space_age_production"] then
  LabPrototypeModifier.set_layer_removal(
    "__factorio_hd_age_space_age_production__/data/space-age/graphics/entity/biolab/biolab-lights.png"
  )
end
