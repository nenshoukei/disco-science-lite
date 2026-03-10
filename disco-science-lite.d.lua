--- @meta
---
--- Type definitions for the public API of Disco Science Lite for Lua Language Server.
---
--- This file depends on Factorio API type definitions provided by the Factorio Modding Tool Kit
--- VS Code extension: https://marketplace.visualstudio.com/items?itemName=justarandomgeek.factoriomod-debug
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
--- @class (exact) LabOverlaySettings
--- @field animation string? Name of [AnimationPrototype](https://lua-api.factorio.com/latest/prototypes/AnimationPrototype.html) to be used as an overlay.
---                          If omitted, the built-in overlay for the standard lab shape is used.
--- @field scale number? Scale of the overlay. (Default: `1`)

--- Public interface `_G.DiscoScience` for other mods on prototype stage.
---
--- You can use it like `DiscoScience.prepareLab(...)`.
---
--- Available in `data.lua`, `data-updates.lua`, and `data-final-fixes.lua`.
---
--- Compatible with the original DiscoScience mod interface.
--- @class DiscoScienceInterface
_G.DiscoScience = {

  --- Prepare a lab prototype for Disco Science colorization.
  ---
  --- `settings` can be used to specify the overlay animation and scale.
  --- If not passed, the default settings are used.
  --- These settings can be overridden at runtime via `remote.call()`.
  ---
  --- Settings:
  --- - `animation` -
  ---     Name of [AnimationPrototype](https://lua-api.factorio.com/latest/prototypes/AnimationPrototype.html) to be used as an overlay.
  ---     If omitted, the built-in overlay for the standard lab shape is used.
  --- - `scale` -
  ---     Scale of the overlay. (Default: `1`)
  ---
  --- @param lab data.LabPrototype Lab prototype to be prepared.
  --- @param settings LabOverlaySettings? Settings for the lab overlay.
  prepareLab = function (lab, settings) end,

  --- Set the color of an ingredient (science pack) at prototype stage.
  ---
  --- These colors can be overridden at runtime via `remote.call()`.
  ---
  --- @param item_name string Item prototype name of the ingredient.
  --- @param color Color
  setIngredientColor = function (item_name, color) end,

  --- Get the color of an ingredient (science pack) registered so far.
  ---
  --- @param item_name string Item prototype name of the ingredient.
  --- @return Color|nil color Color for the ingredient, or `nil` if not registered.
  getIngredientColor = function (item_name) end,

}

--- Runtime interface via `remote.call("DiscoScience", ...)`.
---
--- Available in `control.lua`.
---
--- Compatible with the original DiscoScience mod interface.
--- @class DiscoScienceRemote
local DiscoScienceRemote = {

  --- Set the scale of a lab overlay.
  ---
  --- @deprecated Use `DiscoScience.prepareLab()` at the prototype stage instead.
  --- This function is kept for compatibility with the original DiscoScience mod.
  ---
  --- @param lab_name string Lab prototype name.
  --- @param scale number Scale of the overlay. Must be a positive number.
  setLabScale = function (lab_name, scale) end,

  --- Set the color of an ingredient (science pack) at runtime.
  ---
  --- Overrides colors set at prototype stage.
  ---
  --- @param item_name string Item prototype name of the ingredient.
  --- @param color Color
  setIngredientColor = function (item_name, color) end,

  --- Get the color of an ingredient (science pack).
  ---
  --- @param item_name string Item prototype name of the ingredient.
  --- @return Color|nil color Color for the ingredient, or `nil` if not registered.
  getIngredientColor = function (item_name) end,

}

-- For Factorio Modding Tool Kit Extension for VS Code
-- https://github.com/justarandomgeek/vscode-factoriomod-debug/blob/current/doc/language-lua.md#remote-interfaces
remote.add_interface("DiscoScience", DiscoScienceRemote)
