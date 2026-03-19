# API for Mod Authors

Disco Science Lite exposes APIs for other mods to integrate with. Two APIs are available depending on the stage. These are drop-in compatible with the original Disco Science mod, so existing mods targeting Disco Science can work without code changes.

## Quick Start

### Add dependency to your mod

To use the APIs, add `"? disco-science-lite"` to your mod's [dependencies](https://lua-api.factorio.com/latest/auxiliary/mod-structure.html#dependencies) in `info.json` to ensure correct load order.

```json
{
    "dependencies": ["? disco-science-lite"]
}
```

Prefix `? ` means an optional dependency. Use `(?) ` instead if you want to hide it from the dependency list shown in the mod browser.

### If your mod adds custom science packs

Vanilla science pack colors are built-in. For custom science packs, register the color of each one in `data.lua`:

```lua
-- data.lua
if DiscoScience then
    DiscoScience.setIngredientColor("my-science-pack", { r = 1, g = 0.5, b = 0 })
end
```

Labs that consume this science pack will be tinted with this color.

This code is compatible with both the original Disco Science mod and Disco Science Lite.

The `if DiscoScience then` guard is required because Disco Science Lite is an optional dependency — if the player has not installed it, `DiscoScience` will be `nil`.

### If your mod adds a custom lab

Register your lab in `data.lua`:

```lua
-- data.lua
if DiscoScience then
    DiscoScience.prepareLab(data.raw["lab"]["my-lab"])
end
```

Disco Science Lite colorizes the lab based on the science packs it consumes.

This code is compatible with both the original Disco Science mod and Disco Science Lite.

### If your mod adds a custom lab with a unique shape <kbd>Lite only</kbd>

If you want the color effect to align with your lab's specific shape, you can provide a custom overlay animation:

```lua
-- data.lua
if DiscoScience and DiscoScience.isLite then
    DiscoScience.prepareLab(data.raw["lab"]["my-lab"], { animation = "my-lab-overlay-animation" })
end
```

See [How to define a custom animation](#how-to-define-a-custom-animation) below for details.

This is a Disco Science Lite–specific feature. The custom animation is not supported by the original Disco Science — use `DiscoScience.isLite` to guard Lite-only code.

---

## Compatibility with the Original Disco Science Mod

If your mod already supports the original Disco Science mod, it may work with Disco Science Lite without any changes — but there is one common pitfall to check.

### Check your mod-name guards

The original Disco Science mod's name is `"DiscoScience"`. Some mods guard their integration code by checking for this mod name directly:

```lua
-- data.lua / data-updates.lua / data-final-fixes.lua
if mods["DiscoScience"] then          -- ❌ Does not detect Disco Science Lite
    DiscoScience.prepareLab(...)
end

-- control.lua
if script.active_mods["DiscoScience"] then  -- ❌ Does not detect Disco Science Lite
    remote.call("DiscoScience", ...)
end
```

These guards will not trigger when only Disco Science Lite is installed. Replace them with the interface-based guards instead:

```lua
-- data.lua / data-updates.lua / data-final-fixes.lua
if DiscoScience then                  -- ✅ Works with both mods
    DiscoScience.prepareLab(...)
end

-- control.lua
if remote.interfaces["DiscoScience"] then   -- ✅ Works with both mods
    remote.call("DiscoScience", ...)
end
```

Both Disco Science and Disco Science Lite expose the same `DiscoScience` global and `"DiscoScience"` remote interface, so these guards work correctly with either mod installed.

### No changes needed for API calls

The following calls work as-is with Disco Science Lite — no modifications required:

- `DiscoScience.prepareLab(lab)` — uses the vanilla lab overlay, matching the original mod's behavior
- `remote.call("DiscoScience", "setLabScale", lab_name, scale)` — works identically
- `remote.call("DiscoScience", "setIngredientColor", item_name, color)` — works identically
- `remote.call("DiscoScience", "getIngredientColor", item_name)` — works identically

---

## How to define a custom animation

When no custom animation is defined, Disco Science Lite uses the vanilla lab overlay for any lab registered via `prepareLab()`. For labs that were not registered at all, the [general glow effect](/graphics/general-overlay.png) is rendered as a fallback (when the `Automatic colorization for unsupported mods` setting is enabled), which may look unsuitable sometimes.

If your lab has a unique shape and you want the color effect to align with it — highlighting specific parts of the sprite rather than glowing uniformly — you can define a custom animation.

The animation is rendered on top of the lab entity and tinted by [LuaRenderObject.color](https://lua-api.factorio.com/latest/classes/LuaRenderObject.html#color) to produce the colorization effect. Use `blend_mode = "additive"` and `draw_as_glow = true` so that the overlay glows and blends naturally with the lab sprite beneath it.

For best results, the animation sprite should be a **grayscale image**: white (or bright) pixels in areas that should be colored and glow, and black pixels in areas that should remain invisible.

### Example code

```lua
-- data.lua (or data-updates.lua / data-final-fixes.lua)
if DiscoScience and DiscoScience.isLite then
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

    DiscoScience.prepareLab(data.raw["lab"]["my-lab"], { animation = "my-lab-overlay-animation" })
end
```

Note: Because the custom animation feature is not supported by the original Disco Science mod, the `DiscoScience.isLite` guard is required.

### Example animation sprites

- [lab-overlay.png](/graphics/factorio/lab-overlay.png) is for the vanilla labs.
- [biolab-overlay.png](/graphics/factorio/biolab-overlay.png) is for the vanilla biolabs.

These are auto-generated from the Factorio official assets by [Python script](/tasks/graphics/mods/factorio.py).

> [!NOTE]
> Due to a Factorio technical limitation, it is not possible to synchronize the overlay animation with the lab entity's animation. Even if `animation_offset = 0` is specified in [rendering.draw_animation()](https://lua-api.factorio.com/latest/classes/LuaRendering.html#draw_animation), the actual starting frame of the animation is determined by the current tick count at the time of rendering. For this reason, it is recommended to use a **looping animation without a distinct starting frame**, so that the lack of synchronization is not noticeable.

---

## API

<kbd>Lite only</kbd> : Only available in Disco Science Lite. Not available in the original Disco Science.

### Prototype Stage — `DiscoScience`

Available in `data.lua`, `data-updates.lua`, and `data-final-fixes.lua`.

#### `DiscoScience.isLite` <kbd>Lite only</kbd>

Always `true` when running on Disco Science Lite. In the original Disco Science mod, this field is `nil`.

```lua
if DiscoScience and DiscoScience.isLite then
    -- Disco Science Lite-specific code
end
```

#### `DiscoScience.prepareLab(lab, settings?)`

Prepare a lab prototype for Disco Science colorization.

If the lab was excluded by `DiscoScience.excludeLab()`, this cancels the exclusion.

**Parameters:**

| Parameter  | Type                                                                             | Description                           |
| ---------- | -------------------------------------------------------------------------------- | ------------------------------------- |
| `lab`      | [LabPrototype](https://lua-api.factorio.com/latest/prototypes/LabPrototype.html) | The lab prototype to colorize         |
| `settings` | `DiscoScience.PrepareLabSettings?`                                               | Optional overlay settings (see below) |

**`DiscoScience.PrepareLabSettings`:**

| Field       | Type      | Default             | Description                                                                                                                                                                         |
| ----------- | --------- | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `animation` | `string?` | vanilla lab overlay | <kbd>Lite only</kbd> Name of [AnimationPrototype](https://lua-api.factorio.com/latest/prototypes/AnimationPrototype.html) for [custom animation](#how-to-define-a-custom-animation) |

#### `DiscoScience.excludeLab(lab)` <kbd>Lite only</kbd>

Exclude a lab prototype from Disco Science colorization. Use this if your mod adds a lab that should not be colorized even if the `Automatic colorization for unsupported mods` setting is enabled.

**Parameters:**

| Parameter | Type                                                                                       | Description                                         |
| --------- | ------------------------------------------------------------------------------------------ | --------------------------------------------------- |
| `lab`     | [LabPrototype](https://lua-api.factorio.com/latest/prototypes/LabPrototype.html) or string | The lab prototype to exclude, or its prototype name |

**Example:**

```lua
-- data.lua (or data-updates.lua / data-final-fixes.lua)
if DiscoScience and DiscoScience.isLite then
    DiscoScience.excludeLab(data.raw["lab"]["my-lab"])
    -- or equivalently:
    -- DiscoScience.excludeLab("my-lab")
end
```

This is a Disco Science Lite–specific feature. The original Disco Science mod does not have `excludeLab`. Use `DiscoScience.isLite` to guard Lite-only code.

#### `DiscoScience.setIngredientColor(item_name, color)` <kbd>Lite only</kbd>

Set the color of an ingredient (science pack) at prototype stage. These colors can be overridden at runtime via `remote.call()`.

**Parameters:**

| Parameter   | Type                                                          | Description                                    |
| ----------- | ------------------------------------------------------------- | ---------------------------------------------- |
| `item_name` | `string`                                                      | Item prototype name of the ingredient          |
| `color`     | [Color](https://lua-api.factorio.com/latest/types/Color.html) | Color table (`{r, g, b}` or `{[1], [2], [3]}`) |

#### `DiscoScience.getIngredientColor(item_name)` <kbd>Lite only</kbd>

Get the color of an ingredient (science pack) registered so far.

**Parameters:**

| Parameter   | Type     | Description                           |
| ----------- | -------- | ------------------------------------- |
| `item_name` | `string` | Item prototype name of the ingredient |

**Returns:**

- [Color](https://lua-api.factorio.com/latest/types/Color.html) — Color for the ingredient, or `nil` if not registered.

---

### Runtime Stage — `remote.call("DiscoScience", ...)`

Available in `control.lua`.

#### `setIngredientColor`

Set the color of an ingredient (science pack) at runtime. Overrides colors set at prototype stage.

```lua
remote.call("DiscoScience", "setIngredientColor", item_name, color)
```

**Parameters:**

| Parameter   | Type                                                          | Description                                    |
| ----------- | ------------------------------------------------------------- | ---------------------------------------------- |
| `item_name` | `string`                                                      | Item prototype name of the ingredient          |
| `color`     | [Color](https://lua-api.factorio.com/latest/types/Color.html) | Color table (`{r, g, b}` or `{[1], [2], [3]}`) |

#### `getIngredientColor`

Get the color of an ingredient (science pack).

```lua
local color = remote.call("DiscoScience", "getIngredientColor", item_name)
```

**Parameters:**

| Parameter   | Type     | Description                           |
| ----------- | -------- | ------------------------------------- |
| `item_name` | `string` | Item prototype name of the ingredient |

**Returns:**

- [Color](https://lua-api.factorio.com/latest/types/Color.html) — Color for the ingredient, or `nil` if not registered.

#### `setLabScale`

Set the scale of a lab overlay at runtime. Works in both the original Disco Science mod and Disco Science Lite. Useful when you want to support both mods with a single `control.lua` code path.

```lua
remote.call("DiscoScience", "setLabScale", lab_name, scale)
```

**Parameters:**

| Parameter  | Type     | Description                            |
| ---------- | -------- | -------------------------------------- |
| `lab_name` | `string` | Lab prototype name                     |
| `scale`    | `number` | Scale of the overlay. Positive number. |

---

## Type Definitions

### For Lua Language Server

[disco-science-lite.d.lua](/disco-science-lite.d.lua) is a type definition file for [Lua Language Server (LuaLS)](https://luals.github.io/). It provides type-safe access to `DiscoScience.*` and `remote.call("DiscoScience", ...)` in your editor.

**Option 1: Copy into your project**

Copy [disco-science-lite.d.lua](/disco-science-lite.d.lua) directly into your mod project. The file is licensed under the MIT License — no need to include a separate LICENSE file.

**Option 2: Add to `workspace.library`**

Add the path to the file in your LuaLS settings. For VS Code, add to `.vscode/settings.json`:

```json
{
    "Lua.workspace.library": [
        "/path/to/factorio/mods/disco-science-lite/disco-science-lite.d.lua"
    ]
}
```

See the [LuaLS documentation](https://luals.github.io/wiki/settings/#workspacelibrary) for details.

### For TypeScriptToLua

[disco-science-lite.d.ts](/disco-science-lite.d.ts) is a type definition file for [TypeScriptToLua](https://typescripttolua.github.io/) users. It works with both [typed-factorio](https://github.com/GlassBricks/typed-factorio) and [factorio-types](https://github.com/sguest/factorio-types) packages through structural compatibility — no direct dependency on either package is required.

**Option 1: Copy into your project**

Copy [disco-science-lite.d.ts](/disco-science-lite.d.ts) directly into your mod project. The file is licensed under the MIT License — no need to include a separate LICENSE file.

**Option 2: Reference from the disco-science-lite mod directory**

Add the path to the file in your `tsconfig.json`:

```jsonc
// tsconfig.json
{
    "include": [
        "src/**/*",
        "../disco-science-lite/disco-science-lite.d.ts", // adjust path as needed
    ],
}
```

Or add a triple-slash reference in one of your `.d.ts` files:

```typescript
/// <reference path="../disco-science-lite/disco-science-lite.d.ts" />
```
