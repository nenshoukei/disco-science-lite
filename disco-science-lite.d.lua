--- @meta
---
--- This file contains type definitions of public API of Disco Science Lite for Lua Language Server.
---
--- Add this file's path to your LuaLS `workspace.library` settings to use the public API type-safely.
--- (For VS Code, `"Lua.workspace.library": ["<path to this file>"]` in `.vscode/settings.json`)
--- https://luals.github.io/wiki/settings/#workspacelibrary
---
--- Or, you can simply copy this file into your mod project.
--- This file is licensed under the MIT License. (You don't need LICENSE file to copy this file)
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
--- @field scale integer? Scale of the overlay. (Default: `1`)

--- Public interface `_G.DiscoScience` for other mods on prototype stage.
---
--- You can use it like `DiscoScience.prepareLab(...)`.
---
--- Available in `data.lua`, `data-updates.lua`, and `data-final-fixes.lua`.
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
  --- @param name string Item prototype name of the ingredient.
  --- @param color Color
  setIngredientColor = function (name, color) end,

  --- Get the color of an ingredient (science pack) registered so far.
  ---
  --- @param name string Item prototype name of the ingredient.
  --- @return Color|nil color Color for the ingredient, or `nil` if not registered.
  getIngredientColor = function (name) end,

}

--- Runtime interface via `remote.call("DiscoScience", ...)`.
---
--- Available in `control.lua`, `control-updates.lua` and `control-final-fixes.lua`.
---
--- Factorio Modding Tool Kit Extension for VS Code supports [typings on remote calls](https://github.com/justarandomgeek/vscode-factoriomod-debug/blob/current/doc/language-lua.md#remote-interfaces).
---
--- @class DiscoScienceRemote
local DiscoScienceRemote = {

  --- Register (or re-register) a lab type for Disco Science colorization.
  ---
  --- `settings` can be used to specify the overlay animation and scale.
  --- If not passed, the default settings are used.
  --- This overrides settings registered by `DiscoScience.prepareLab()` at prototype stage.
  ---
  --- Settings:
  --- - `animation` -
  ---     Name of [AnimationPrototype](https://lua-api.factorio.com/latest/prototypes/AnimationPrototype.html) to be used as an overlay.
  ---     If omitted, the built-in overlay for the standard lab shape is used.
  --- - `scale` -
  ---     Scale of the overlay. (Default: `1`)
  ---
  --- @param lab_name string Lab prototype name.
  --- @param settings LabOverlaySettings? Settings for the lab overlay.
  registerLab = function (lab_name, settings) end,

  --- Set the scale of a lab overlay.
  ---
  --- If the lab has not been registered yet, it will be registered with default settings.
  ---
  --- @param lab_name string Lab prototype name.
  --- @param scale integer Scale of the overlay. Must be a positive number.
  setLabScale = function (lab_name, scale) end,

  --- Set the color of an ingredient (science pack) at runtime.
  ---
  --- Overrides colors set at prototype stage.
  ---
  --- @param name string Item prototype name of the ingredient.
  --- @param color Color
  setIngredientColor = function (name, color) end,

  --- Get the color of an ingredient (science pack).
  ---
  --- @param name string Item prototype name of the ingredient.
  --- @return Color|nil color Color for the ingredient, or `nil` if not registered.
  getIngredientColor = function (name) end,

}

remote.add_interface("DiscoScience", DiscoScienceRemote)
