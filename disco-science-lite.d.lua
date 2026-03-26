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

--- Options for `DiscoScience.prepareLab()`.
---
--- @class (exact) DiscoScience.PrepareLabOptions
--- @field animation string? Name of [AnimationPrototype](https://lua-api.factorio.com/latest/prototypes/AnimationPrototype.html) to be used as a custom overlay animation.

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

  --- `true` when running on Disco Science Lite. `nil` on the original Disco Science mod.
  ---
  --- Use this to distinguish between the two mods:
  --- ```lua
  --- if DiscoScience and DiscoScience.isLite then
  ---     -- Disco Science Lite-specific code
  --- end
  --- ```
  ---
  --- @type true
  isLite = true,

  --- Exclude a lab prototype from Disco Science colorization.
  ---
  --- The lab will not receive a color overlay, even when the `Automatic colorization for unsupported mods` setting is enabled.
  ---
  --- Calling `prepareLab()` on the same lab later removes the exclusion.
  ---
  --- @param lab DiscoScience.LabPrototype | string Lab to exclude, or its prototype name.
  excludeLab = function (lab) end,

  --- Prepare a lab prototype for Disco Science colorization.
  ---
  --- When `options.animation` is omitted, the vanilla lab overlay is used and `lab.on_animation`
  --- is frozen on the first frame (matching the original Disco Science mod behavior of
  --- `lab.on_animation = lab.off_animation`).
  ---
  --- When `options.animation` is provided, the custom overlay is used and `lab.on_animation`
  --- is left unchanged. You are responsible for freezing or modifying it as needed.
  ---
  --- To use a custom overlay aligned to your lab's unique shape, specify `options.animation`.
  ---
  --- @param lab DiscoScience.LabPrototype Lab to register for Disco Science colorization.
  --- @param options DiscoScience.PrepareLabOptions? Custom overlay options.
  prepareLab = function (lab, options) end,

}

--- Runtime interface via `remote.call("DiscoScience", ...)`.
---
--- Available in `control.lua`.
---
--- Compatible with the original DiscoScience mod interface.
--- @class DiscoScience.Remote
local DiscoScienceRemote = {

  --- Set the scale of a lab overlay at runtime.
  ---
  --- Works in both the original Disco Science mod and Disco Science Lite.
  --- Useful when you want to support both mods with a single `control.lua` code path.
  ---
  --- @param lab_name string Lab prototype name.
  --- @param scale number Scale of the overlay. Must be a positive number.
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
