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

These files are included only as part of this mod.
```

### 2. Add entry to `README.md` License section

Append a new bullet point after the last existing entry under "However, some image assets..." in `## License`:

**If truly open source:**

```markdown
- Image files under [graphics/<DirName>/](graphics/<DirName>/) are derived from assets of the
  [<Mod Name>](<Mod URL>) Factorio mod created by <Author>,
  licensed under the <License> (<License SPDX>).
  See [LICENSE](graphics/<DirName>/LICENSE) and [NOTICE.txt](graphics/<DirName>/NOTICE.txt) for details.
```

**If not truly open source:**

```markdown
- Image files under [graphics/<DirName>/](graphics/<DirName>/) are derived from assets of the
  [<Mod Name>](<Mod URL>) Factorio mod created by <Author>.
  The original mod is indicated on the Factorio Mod Portal as being licensed under the <License>.
  These files are treated as being redistributed under the terms of the <License SPDX>.
  See [<LICENSE FILE>](graphics/<DirName>/<LICENSE FILE>) and [NOTICE.txt](graphics/<DirName>/NOTICE.txt) for details.
```

### 3. Update `docs/mod-portal/description.md` License section

Add a new bullet to the list of third-party asset sources:

```markdown
- [<Mod Name>](<Mod URL>) by <Author>
```

## Notes

- The user will copy the LICENSE file manually — do not create it.
- Follow the style of existing entries in `README.md` for consistency.
- Keep `description.md` concise — it is a mod portal page, not a detailed legal document.
