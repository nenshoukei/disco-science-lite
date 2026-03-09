# Disco Science Lite

---

## API for Mod Authors

Disco Science Lite exposes APIs for other mods to integrate with. Two APIs are available depending on the stage. Compatible with the original Disco Science mod.

### Quick Start

#### Add dependency to your mod

To use the APIs, add `"? disco-science-lite"` to your mod's [dependencies](https://lua-api.factorio.com/latest/auxiliary/mod-structure.html#dependencies) in `info.json` to ensure correct load order.

```json
{
    "dependencies": ["? disco-science-lite"]
}
```

Prefix `? ` means an optional dependency. Use `(?) ` instead if you want to hide Disco Science Lite from your dependency list.

#### If your mod adds a custom lab

Register your lab in `data.lua`:

```lua
-- data.lua
if _G.DiscoScience then
    DiscoScience.prepareLab(data.raw["lab"]["my-lab"])
end
```

That's it — Disco Science Lite colorizes the lab based on the science packs it consumes.

If your lab has a **different shape from the vanilla lab**, provide a custom overlay animation so the glow aligns correctly:

```lua
-- data.lua
if _G.DiscoScience then
    DiscoScience.prepareLab(data.raw["lab"]["my-lab"], { animation = "my-lab-overlay-animation" })
end
```

Without a custom animation, the built-in overlay designed for the vanilla lab shape is used, which may look misaligned on differently-shaped labs. See [Prototype Stage API](#prototype-stage--_gdiscoscience) below for how to define a custom animation.

#### If your mod adds custom science packs

Register the color of each science pack in `data.lua`:

```lua
-- data.lua
if _G.DiscoScience then
    DiscoScience.setIngredientColor("my-science-pack", { r = 1, g = 0.5, b = 0 })
end
```

Labs that consume this science pack will be tinted with this color.

---

### Prototype Stage — `_G.DiscoScience`

Available in `data.lua`, `data-updates.lua`, and `data-final-fixes.lua`.

```lua
-- Prepare a lab prototype for Disco Science colorization.
-- Must be called before the runtime stage.
-- `settings` is optional; omit to use defaults.
DiscoScience.prepareLab(lab, settings)

-- Set the color of an ingredient (science pack).
-- Can be overridden at runtime via remote.call().
DiscoScience.setIngredientColor(item_name, color)

-- Get the color of an ingredient registered so far.
-- Returns nil if not registered.
DiscoScience.getIngredientColor(item_name)
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

| Parameter   | Type                                                                                  | Description                                    |
| ----------- | ------------------------------------------------------------------------------------- | ---------------------------------------------- |
| `lab`       | [data.LabPrototype](https://lua-api.factorio.com/latest/prototypes/LabPrototype.html) | The lab prototype to colorize                  |
| `settings`  | `LabOverlaySettings?`                                                                 | Optional overlay settings (see below)          |
| `item_name` | `string`                                                                              | Item prototype name of the ingredient          |
| `color`     | [Color](https://lua-api.factorio.com/latest/types/Color.html)                         | Color table (`{r, g, b}` or `{[1], [2], [3]}`) |

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

If `animation` is omitted, Disco Science Lite uses its built-in overlay animation, which is designed for the vanilla Factorio lab shape. For custom labs with a different shape or size, this may look misaligned — it is recommended to always provide a custom animation for such labs.

For labs that are **not registered** via `prepareLab()` or `registerLab()` at all, Disco Science Lite will use a generic grow animation as a fallback overlay when the fallback option is enabled in mod settings. If you want to explicitly use this generic animation for your labs, specify `animation = "mks-dsl-general-overlay"`. (The `mks-dsl-` prefix is used to avoid name collisions with other mods: `mks` is the author's identifier and `dsl` stands for Disco Science Lite.)

### Runtime Stage — `remote.call("DiscoScience", ...)`

Available in `control.lua` and other runtime scripts.

**When to use `registerLab` vs `prepareLab`:** Prefer `prepareLab` at the prototype stage when possible — it runs earlier and is available in `data.lua`. Use `registerLab` at runtime only when registration cannot happen at the prototype stage, for example when lab settings depend on runtime state or other runtime conditions.

```lua
-- Register (or re-register) a lab type for colorization.
-- Overrides settings registered by DiscoScience.prepareLab() at prototype stage.
remote.call("DiscoScience", "registerLab", lab_name, settings)

-- Set the scale of a lab overlay.
-- Auto-registers the lab with default settings if not already registered.
remote.call("DiscoScience", "setLabScale", lab_name, scale)

-- Set the color of an ingredient (science pack).
-- Overrides colors set at prototype stage.
remote.call("DiscoScience", "setIngredientColor", item_name, color)

-- Get the color of an ingredient.
-- Returns nil if not registered.
remote.call("DiscoScience", "getIngredientColor", item_name)
```

**Example:**

```lua
-- control.lua
if remote.interfaces["DiscoScience"] then
    remote.call("DiscoScience", "registerLab", "my-lab", { scale = 2 })
    remote.call("DiscoScience", "setLabScale", "my-lab", 3)
    remote.call("DiscoScience", "setIngredientColor", "my-science-pack", { r = 1, g = 0.5, b = 0 })
    local color = remote.call("DiscoScience", "getIngredientColor", "my-science-pack")
end
```

**Parameters:**

| Parameter   | Type                                                          | Description                                                                                     |
| ----------- | ------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| `lab_name`  | `string`                                                      | Lab prototype name                                                                              |
| `settings`  | `LabOverlaySettings`                                          | Overlay settings table (same fields as above); must be a table — use `{}` to apply all defaults |
| `scale`     | `number`                                                      | Positive number for overlay scale (Default scale is `1`)                                        |
| `item_name` | `string`                                                      | Item prototype name of the ingredient                                                           |
| `color`     | [Color](https://lua-api.factorio.com/latest/types/Color.html) | Color table (`{r, g, b}` or `{[1], [2], [3]}`)                                                  |

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
