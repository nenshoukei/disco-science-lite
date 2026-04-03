--- Science Pack Galore (Forked) by Semenar
--- https://mods.factorio.com/mod/SciencePackGalore
--- Science Pack Galore (Forked) by nihilistzsche
--- https://mods.factorio.com/mod/SciencePackGaloreForked

if not (mods["SciencePackGaloreForked"] or mods["SciencePackGalore"]) then return {} end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

return {
  on_data = function ()
    PrototypeColorRegistry.set_by_table({
      ["sem-spg_science-pack-1"]  = { 0.81, 0.27, 0.28 },
      ["sem-spg_science-pack-2"]  = { 0.80, 0.35, 0.28 },
      ["sem-spg_science-pack-3"]  = { 0.80, 0.43, 0.28 },
      ["sem-spg_science-pack-4"]  = { 0.80, 0.51, 0.29 },
      ["sem-spg_science-pack-5"]  = { 0.80, 0.60, 0.29 },
      ["sem-spg_science-pack-6"]  = { 0.80, 0.69, 0.30 },
      ["sem-spg_science-pack-7"]  = { 0.79, 0.77, 0.30 },
      ["sem-spg_science-pack-8"]  = { 0.70, 0.77, 0.30 },
      ["sem-spg_science-pack-9"]  = { 0.61, 0.77, 0.30 },
      ["sem-spg_science-pack-10"] = { 0.51, 0.77, 0.29 },
      ["sem-spg_science-pack-11"] = { 0.42, 0.77, 0.30 },
      ["sem-spg_science-pack-12"] = { 0.34, 0.77, 0.29 },
      ["sem-spg_science-pack-13"] = { 0.26, 0.77, 0.29 },
      ["sem-spg_science-pack-14"] = { 0.25, 0.77, 0.37 },
      ["sem-spg_science-pack-15"] = { 0.25, 0.77, 0.44 },
      ["sem-spg_science-pack-16"] = { 0.24, 0.77, 0.52 },
      ["sem-spg_science-pack-17"] = { 0.24, 0.78, 0.60 },
      ["sem-spg_science-pack-18"] = { 0.23, 0.78, 0.69 },
      ["sem-spg_science-pack-19"] = { 0.22, 0.78, 0.78 },
      ["sem-spg_science-pack-20"] = { 0.22, 0.65, 0.73 },
      ["sem-spg_science-pack-21"] = { 0.22, 0.61, 0.78 },
      ["sem-spg_science-pack-22"] = { 0.22, 0.49, 0.73 },
      ["sem-spg_science-pack-23"] = { 0.23, 0.45, 0.77 },
      ["sem-spg_science-pack-24"] = { 0.23, 0.38, 0.78 },
      ["sem-spg_science-pack-25"] = { 0.23, 0.31, 0.77 },
      ["sem-spg_science-pack-26"] = { 0.32, 0.29, 0.76 },
      ["sem-spg_science-pack-27"] = { 0.45, 0.30, 0.78 },
      ["sem-spg_science-pack-28"] = { 0.50, 0.29, 0.76 },
      ["sem-spg_science-pack-29"] = { 0.64, 0.30, 0.78 },
      ["sem-spg_science-pack-30"] = { 0.65, 0.29, 0.73 },
      ["sem-spg_science-pack-31"] = { 0.78, 0.30, 0.77 },
      ["sem-spg_science-pack-32"] = { 0.78, 0.29, 0.68 },
      ["sem-spg_science-pack-33"] = { 0.79, 0.28, 0.59 },
      ["sem-spg_science-pack-34"] = { 0.78, 0.28, 0.50 },
      ["sem-spg_science-pack-35"] = { 0.80, 0.28, 0.43 },
      ["sem-spg_science-pack-36"] = { 0.79, 0.27, 0.35 },
    })
  end,
}
