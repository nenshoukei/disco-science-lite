---
name: add-supported-mod
description: Use when adding support for a new Factorio mod to disco-science-lite. Invoked via /add-supported-mod.
---

# Add Supported Mod

Use this skill to add support for a new Factorio mod to disco-science-lite.

## Step 1: Collect Information

Ask the user for the following (if not already provided via $ARGUMENTS):

- **Mod name**: The display name of the mod (e.g. "Cerys")
- **Mod ID**: The ID used in the mod URL (e.g. `Cerys-Moon-of-Fulgora` from `https://mods.factorio.com/mod/Cerys-Moon-of-Fulgora`)
- **Author name**: The mod author's display name (e.g. `thesixthroc`)
- **Planet mod?**: Whether this is a Space-Age planet-adding mod (Yes/No)

If the user provides a Factorio Mod Portal URL like `https://mods.factorio.com/mod/secretas?from=downloaded`, extract the Mod ID as `secretas` (the path segment after `/mod/`, excluding query strings).

## Step 2: Create Lua File

Create `scripts/prototype/mods/<Mod ID>.lua` using this template:

```lua
--- <Mod name> by <Author name>
--- https://mods.factorio.com/mod/<Mod ID>

if not mods["<Mod ID>"] then return end

local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local AnimationHelpers = require("scripts.prototype.animation-helpers")

return {
  on_data = function ()

  end,

  on_data_final_fixes = function ()

  end,
}
```

## Step 3: Update README.md

Add the following line to the `## Supported Mods` section of `README.md`:

```markdown
- [<Mod name>](https://mods.factorio.com/mod/<Mod ID>) by <Author name>
```

**Insertion rules:**

- If **not** a planet mod: Insert among the top-level bullet list items, in alphabetical order by mod name (case-insensitive, ignore leading symbols like 🌐).
- If **a planet mod**: Insert as a sub-item under `- Space-Age Planet Mods`, in alphabetical order by mod name (case-insensitive, ignore leading symbols).

## Step 4: Run make check

Run the following command to update `_all.lua` and mod description:

```bash
make mods mod-description
```

Run from the project root directory: `/Users/kotas/Library/Application Support/factorio/mods/disco-science-lite`

## Notes

- The function body (`on_data = function () ... end`) is intentionally left empty — the user will fill in the actual implementation.
- Do not add extra imports beyond the three standard ones unless the user asks.
- Follow alphabetical order strictly for README.md insertion.
