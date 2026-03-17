--- @meta
---
--- Type definitions for the public API of Disco Science Lite for Lua Language Server.
---
--- ## MIT License
---
--- Copyright (c) 2019 Daniel Brauer
--- Copyright (c) 2026 mokkosu55 a.k.a. nenshoukei
---
--- Permission is hereby granted, free of charge, to any person obtaining a copy
--- of this software and associated documentation files (the "Software"), to deal
--- in the Software without restriction, including without limitation the rights
--- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--- copies of the Software, and to permit persons to whom the Software is
--- furnished to do so, subject to the following conditions:
---
--- The above copyright notice and this permission notice shall be included in all
--- copies or substantial portions of the Software.
---
--- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--- SOFTWARE.
---

--- Settings for rendering a lab overlay.
---
--- @class (exact) DiscoScience.LabOverlaySettings
--- @field animation string? Name of [AnimationPrototype](https://lua-api.factorio.com/latest/prototypes/AnimationPrototype.html) to be used as an overlay.<br>If omitted, auto-detected from the lab's `on_animation` filenames. Falls back to the built-in overlay for the standard lab shape if no match is found.
--- @field scale number? Scale of the overlay. (Default: auto-calculated from the lab's animation when `animation` is auto-detected; `1` otherwise)

--- A color in RGBA format.
---
--- See: https://lua-api.factorio.com/latest/types/Color.html
---
--- @alias DiscoScience.Color { r?: number, g?: number, b?: number, a?: number } | [number, number, number] | [number, number, number, number]

--- Lab Prototype for DiscoScience.prepareLab()
---
--- See: https://lua-api.factorio.com/latest/prototypes/LabPrototype.html
---
--- @alias DiscoScience.LabPrototype { type: "lab", name: string }

--- Public interface `DiscoScience` for other mods on prototype stage.
---
--- You can use it like `DiscoScience.prepareLab(...)`.
---
--- Available in `data.lua`, `data-updates.lua`, and `data-final-fixes.lua`.
---
--- Compatible with the original DiscoScience mod interface.
---
--- @class DiscoScience.Interface
_G.DiscoScience = {

  --- Prepare a lab prototype for Disco Science colorization.
  ---
  --- When `settings.animation` is omitted, the overlay animation is auto-detected from
  --- filenames in the lab's `on_animation`. The scale is also auto-calculated from the
  --- matching layer if `settings.scale` is omitted.
  ---
  --- @param lab DiscoScience.LabPrototype Lab prototype to be prepared.
  --- @param settings DiscoScience.LabOverlaySettings? Settings for the lab overlay. If omitted, both animation and scale are auto-detected.
  prepareLab = function (lab, settings) end,

  --- Set the color of an ingredient (science pack) at prototype stage.
  ---
  --- These colors can be overridden at runtime via `remote.call()`.
  ---
  --- @param item_name string Item prototype name of the ingredient.
  --- @param color DiscoScience.Color Color for the ingredient.
  setIngredientColor = function (item_name, color) end,

  --- Get the color of an ingredient (science pack) registered so far.
  ---
  --- @param item_name string Item prototype name of the ingredient.
  --- @return DiscoScience.Color|nil color Color for the ingredient, or `nil` if not registered.
  getIngredientColor = function (item_name) end,

}

--- Runtime interface via `remote.call("DiscoScience", ...)`.
---
--- Available in `control.lua`.
---
--- Compatible with the original DiscoScience mod interface.
--- @class DiscoScience.Remote
local DiscoScienceRemote = {

  --- Set the scale of a lab overlay.
  ---
  --- [DEPRECATED] Use `DiscoScience.prepareLab()` at the prototype stage instead.
  --- This function is kept for compatibility with the original DiscoScience mod.
  ---
  --- @param lab_name string Lab prototype name.
  --- @param scale number Scale of the overlay. Must be a positive number.
  --- @deprecated
  setLabScale = function (lab_name, scale) end,

  --- Set the color of an ingredient (science pack) at runtime.
  ---
  --- Overrides colors set at prototype stage.
  ---
  --- @param item_name string Item prototype name of the ingredient.
  --- @param color DiscoScience.Color Color for the ingredient.
  setIngredientColor = function (item_name, color) end,

  --- Get the color of an ingredient (science pack).
  ---
  --- @param item_name string Item prototype name of the ingredient.
  --- @return DiscoScience.Color|nil color Color for the ingredient, or `nil` if not registered.
  getIngredientColor = function (item_name) end,

}

-- For Factorio Modding Tool Kit Extension for VS Code
-- https://github.com/justarandomgeek/vscode-factoriomod-debug/blob/current/doc/language-lua.md#remote-interfaces
remote.add_interface("DiscoScience", DiscoScienceRemote)
