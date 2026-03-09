# Disco Science Lite

---

## API for Mod Authors

Disco Science Lite exposes APIs for other mods to integrate with. Two APIs are available depending on the stage. Compatible with the original Disco Science mod.

To use these APIs, add `"? disco-science-lite"` to your mod's [dependencies](https://lua-api.factorio.com/latest/auxiliary/mod-structure.html#dependencies) in `info.json`. Without this, load order is not guaranteed and your `data.lua` or `control.lua` may be executed before Disco Science Lite is loaded.

```json
{
    "dependencies": ["? disco-science-lite"]
}
```

Prefix `? ` means an optional dependency. Use `(?) ` instead if you want to hide Disco Science Lite from your dependency list.

### Prototype Stage — `_G.DiscoScience`

Available in `data.lua`, `data-updates.lua`, and `data-final-fixes.lua`.

```lua
-- Prepare a lab prototype for Disco Science colorization.
-- Must be called before the runtime stage.
-- `settings` is optional; omit to use defaults.
DiscoScience.prepareLab(lab, settings)

-- Set the color of an ingredient (science pack).
-- Can be overridden at runtime via remote.call().
DiscoScience.setIngredientColor(name, color)

-- Get the color of an ingredient registered so far.
-- Returns nil if not registered.
DiscoScience.getIngredientColor(name)
```

**Example:**

```lua
-- data.lua
local my_lab = data.raw["lab"]["my-lab"]
DiscoScience.prepareLab(my_lab)
DiscoScience.prepareLab(my_lab, { animation = "my-lab-overlay-animation", scale = 2 })
DiscoScience.setIngredientColor("my-science-pack", { r = 1, g = 0.5, b = 0 })
local color = DiscoScience.getIngredientColor("my-science-pack")
```

**Parameters:**

| Parameter  | Type                                                                                  | Description                                    |
| ---------- | ------------------------------------------------------------------------------------- | ---------------------------------------------- |
| `lab`      | [data.LabPrototype](https://lua-api.factorio.com/latest/prototypes/LabPrototype.html) | The lab prototype to colorize                  |
| `settings` | `LabOverlaySettings?`                                                                 | Optional overlay settings (see below)          |
| `name`     | `string`                                                                              | Item prototype name of the ingredient          |
| `color`    | [Color](https://lua-api.factorio.com/latest/types/Color.html)                         | Color table (`{r, g, b}` or `{[1], [2], [3]}`) |

**`LabOverlaySettings`:**

| Field       | Type       | Default          | Description                                                                                                                |
| ----------- | ---------- | ---------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `animation` | `string?`  | built-in overlay | Name of [AnimationPrototype](https://lua-api.factorio.com/latest/prototypes/AnimationPrototype.html) to use as the overlay |
| `scale`     | `integer?` | `1`              | Scale of the overlay                                                                                                       |

**About the `animation` field:**

The animation is rendered on top of the lab entity and tinted by [LuaRenderObject.color](https://lua-api.factorio.com/latest/classes/LuaRenderObject.html#color) to produce the colorization effect. Use `blend_mode = "additive"` and `draw_as_glow = true` so that the overlay glows and blends naturally with the lab sprite beneath it.

For best results, the animation sprite should be a **grayscale image**: white (or bright) pixels in areas that should be colored and glow, and black pixels in areas that should remain invisible.

Example animation prototype definition:

```lua
-- data.lua (or data-updates.lua / data-final-fixes.lua)
data:extend({
  {
    type = "animation",
    name = "my-lab-overlay-animation",
    filename = "__my-mod__/graphics/my-lab-overlay.png",
    blend_mode = "additive",
    draw_as_glow = true,
    width = 216,
    height = 194,
    frame_count = 33,
    line_length = 11,
    animation_speed = 1 / 3,
    scale = 0.5,
  },
})
```

If `animation` is omitted, Disco Science Lite assumes the lab has the same shape as the vanilla Factorio lab and uses its built-in overlay animation for that lab.

For labs that are **not registered** via `prepareLab()` or `registerLab()` at all, Disco Science Lite will use a generic grow animation as a fallback overlay when the fallback option is enabled in mod settings. If you want to use the generic grow animation for your labs, specify `animation = "mks-dsl-general-overlay"`.

### Runtime Stage — `remote.call("DiscoScience", ...)`

Available in `control.lua` and other runtime scripts.

```lua
-- Register (or re-register) a lab type for colorization.
-- Overrides settings registered by DiscoScience.prepareLab() at prototype stage.
remote.call("DiscoScience", "registerLab", lab_name, settings)

-- Set the scale of a lab overlay.
-- Auto-registers the lab with default settings if not already registered.
remote.call("DiscoScience", "setLabScale", lab_name, scale)

-- Set the color of an ingredient (science pack).
-- Overrides colors set at prototype stage.
remote.call("DiscoScience", "setIngredientColor", name, color)

-- Get the color of an ingredient.
-- Returns nil if not registered.
remote.call("DiscoScience", "getIngredientColor", name)
```

**Example:**

```lua
-- control.lua
remote.call("DiscoScience", "registerLab", "my-lab", { scale = 2 })
remote.call("DiscoScience", "setLabScale", "my-lab", 3)
remote.call("DiscoScience", "setIngredientColor", "my-science-pack", { r = 1, g = 0.5, b = 0 })
local color = remote.call("DiscoScience", "getIngredientColor", "my-science-pack")
```

**Parameters:**

| Parameter  | Type                                                          | Description                                    |
| ---------- | ------------------------------------------------------------- | ---------------------------------------------- |
| `lab_name` | `string`                                                      | Lab prototype name                             |
| `settings` | `LabOverlaySettings`                                          | Overlay settings table (same fields as above)  |
| `scale`    | `number`                                                      | Positive number for overlay scale              |
| `name`     | `string`                                                      | Item prototype name of the ingredient          |
| `color`    | [Color](https://lua-api.factorio.com/latest/types/Color.html) | Color table (`{r, g, b}` or `{[1], [2], [3]}`) |

---

### Type Definitions for Lua Language Server

`disco-science-lite.d.lua` is a type definition file for [Lua Language Server (LuaLS)](https://luals.github.io/). It provides type-safe access to `DiscoScience.*` and `remote.call("DiscoScience", ...)` in your editor.

**Option 1: Add to `workspace.library`**

Add the path to this file in your LuaLS settings. For VS Code, add to `.vscode/settings.json`:

```json
{
    "Lua.workspace.library": [
        "/path/to/factorio/mods/disco-science-lite/disco-science-lite.d.lua"
    ]
}
```

See the [LuaLS documentation](https://luals.github.io/wiki/settings/#workspacelibrary) for details.

**Option 2: Copy into your project**

Copy `disco-science-lite.d.lua` directly into your mod project. The file is licensed under the MIT License — no need to include a separate LICENSE file.

## Development

Requirements: `lua`, `luarocks`

To install dependencies by luarocks:

```
make dev
```

To lint:

```
make lint
```

To run unit tests:

```
make test
```

To update image files (requires ImageMagick, Factorio, Space-Age DLC):

```
make graphics
```

## License

The original [Disco Science](https://mods.factorio.com/mod/DiscoScience) mod was created by Daniel Brauer and is licensed under the [MIT License](LICENSE).

This mod is a modified version of the original and is likewise released under the MIT License.

The image files under `graphics/` were generated based on official Factorio assets.
