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
- **Source URL for `on_animation`**: A URL to the source code where the lab's `on_animation` is defined (e.g. a GitHub permalink). May be omitted if no public code repository exists.

If the user provides a Factorio Mod Portal URL like `https://mods.factorio.com/mod/secretas?from=downloaded`, extract the Mod ID as `secretas` (the path segment after `/mod/`, excluding query strings).

## Step 2: Create Lua File

Create `scripts/prototype/mods/<Mod ID>.lua` using this template:

```lua
--- <Mod name> by <Author name>
--- https://mods.factorio.com/mod/<Mod ID>

if not mods["<Mod ID>"] then return {} end

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

## Step 3: Create Spec File

Create `spec/prototype/mods/<Mod ID>_spec.lua`.

### Fixture for `on_data_final_fixes`

**If Source URL is provided**: Use WebFetch to retrieve the source code at that URL and extract the `on_animation` layers array to build the fixture. Use the actual filenames, frame counts, and other properties as written in the source. The comment should be `-- Source: <URL>`.

**If no public code repository**: Add the comment `-- No public code repositories` and build the best fixture you can from available information (e.g. mod portal screenshots or known patterns). If no information is available, use a TODO placeholder.

### Lab name in fixture

Use the actual lab entity name (the key in `data.raw.lab`) from the source code if available. Otherwise use a `"<lab-name>"` placeholder.

### Template

```lua
local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["<Mod ID>"] = "1.0.0"
local Mod = require("scripts.prototype.mods.<Mod ID>")

describe("mods/<Mod ID>", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    PrototypeLabRegistry.reset()
    _G.mods["<Mod ID>"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers colors", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeColorRegistry.registered_colors[""])
    end)

    it("registers labs", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs[""])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- Source: <URL>  (or "-- No public code repositories")
      on_animation = {
        layers = {
          -- extracted from source, or TODO
        },
      }
      _G.data.raw.lab["<lab-name>"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("applies lab modifications", function ()
      Mod.on_data_final_fixes()
      -- TODO: Write assertions
    end)

    it("creates the <lab-name> overlay animation", function ()
      Mod.on_data_final_fixes()
      local overlay = _G.data.raw["animation"]["mks-dsl-<lab-name>-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay -nil
    end)
  end)
end)
```

### Notes on the spec file

- The `on_data` tests have empty string assertions — the actual science pack names and lab names are unknown until the implementation is written.
- The `on_data_final_fixes` test has no assert lines either — just calls `Mod.on_data_final_fixes()`. The user will add asserts once the implementation is written.
- If `on_data_final_fixes` creates overlay or companion animations, `Helper.load_animation_definitions()` must be called at the top of the `before_each`. Add it if you can tell from the source that this will be needed; otherwise, omit it and let the user add it later.

## Step 4: Update README.md and README.ja.md

Add the following line to the `## Supported Mods` section of `README.md`, ad to the `## 対応 Mod` section of `README.ja.md`:

```markdown
- [<Mod name>](https://mods.factorio.com/mod/<Mod ID>) by <Author name>
```

**Insertion rules:**

- If **not** a planet mod: Insert among the top-level bullet list items, in alphabetical order by mod name (case-insensitive, ignore leading symbols like 🌐).
- If **a planet mod**: Insert as a sub-item under `- Space-Age Planet Mods`, in alphabetical order by mod name (case-insensitive, ignore leading symbols).

## Step 5: Run make check

Run the following command to update `_all.lua` and mod description:

```bash
make mods mod-description
```

Run from the project root directory: `/Users/kotas/Library/Application Support/factorio/mods/disco-science-lite`

## Notes

- The function body (`on_data = function () ... end`) is intentionally left empty — the user will fill in the actual implementation.
- Do not add extra imports beyond the three standard ones unless the user asks.
- Follow alphabetical order strictly for README.md insertion.
