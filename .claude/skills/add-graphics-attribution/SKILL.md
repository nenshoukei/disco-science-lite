---
name: add-graphics-attribution
description: Use when adding attribution for a new third-party mod's graphics (NOTICE.txt, README.md License section, description.md).
---

# Add Graphics Attribution

Use this skill when adding image assets derived from a third-party Factorio mod and attribution needs to be set up.

## Required Information

Collect the following before proceeding:

- **Mod name**: The display name of the mod (e.g. "Krastorio 2")
- **Directory name**: The `graphics/<DirName>/` directory where assets are placed (e.g. `Krastorio2`)
- **Mod URL**: URL on the Factorio Mod Portal (e.g. `https://mods.factorio.com/mod/Krastorio2`)
- **Author**: The mod's author name
- **Author URL**: URL to the author's profile (e.g. `https://mods.factorio.com/user/raiguard`)
- **License**: The license (e.g. GNU LGPLv3, MIT)
- **Is truly open source?**: Whether the mod has an actual LICENSE file in the repo (vs. only a label on the Mod Portal)

## Steps

### 1. Create `graphics/<DirName>/NOTICE.txt`

**If truly open source** (has an actual LICENSE file):

```
NOTICE — Derived Assets from "<Mod Name>"

This directory contains image files derived from assets originally distributed as part of the Factorio mod
"<Mod Name>", created by <Author>, licensed under the <License> (<License SPDX>).
<Mod URL>

These files are modified versions of the original assets and are redistributed under the terms of the <License SPDX>.

The full license text is provided in the accompanying LICENSE file.
```

**If not truly open source** (only a license label on the Mod Portal):

```
NOTICE — Derived Assets from "<Mod Name>"

This directory contains image files derived from assets originally distributed as part of the Factorio mod
"<Mod Name>", created by <Author>.
<Mod URL>

The original mod is indicated on the Factorio Mod Portal as being licensed under the
<License> (<License SPDX>).

These files are modified versions of the original assets and are redistributed under the terms of the <License SPDX>.

Original copyright and authorship of the assets remain with <Author>.

The full license text is provided in the accompanying <LICENSE FILE> file.
```

### 2. Add row to `README.md` License table and Acknowledgements

**License table**: Append a new row after the last existing entry in the `## License` table (relative paths):

```markdown
| [graphics/<DirName>/](graphics/<DirName>/) | [<Mod Name>](<Mod URL>) | [<Author>](<Author URL>) | <License> |
```

**Acknowledgements**: Append a new bullet after the last existing entry in `## Acknowledgements`:

```markdown
- **[<Author>](<Author URL>)** — for the graphics from [<Mod Name>](<Mod URL>).
```

### 3. Update `docs/mod-portal/description.md` License table and Acknowledgements

Same format as README.md, but the Files column uses full GitHub URLs instead of relative paths:

**License table**: Append a new row after the last existing entry in the `## License` table (GitHub URLs):

```markdown
| [graphics/<DirName>/](https://github.com/nenshoukei/disco-science-lite/tree/main/graphics/<DirName>/) | [<Mod Name>](<Mod URL>) | [<Author>](<Author URL>) | <License> |
```

**Acknowledgements**: Append a new bullet after the last existing entry in `## Acknowledgements`:

```markdown
- **[<Author>](<Author URL>)** — for the graphics from [<Mod Name>](<Mod URL>).
```

## Notes

- The user will copy the LICENSE file manually — do not create it.
- Follow the style of existing entries in `README.md` for consistency.
- Keep `description.md` concise — it is a mod portal page, not a detailed legal document.
- The License table columns are: Files | Source | Author | License. Keep column widths aligned with existing rows.
