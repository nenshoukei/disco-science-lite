---
paths:
    - "**/*.lua"
    - "data*.lua"
    - "control*.lua"
    - "settings*.lua"
    - "migrations/**"
    - "locale/**"
---

# Factorio Mod Development

## Stages

- Settings stage: `settings.lua` → `settings-updates.lua` → `settings-final-fixes.lua`
- Prototype stage: `data.lua` → `data-updates.lua` → `data-final-fixes.lua`
- Runtime stage: `control.lua`

## Storage

On runtime, `storage` is a table automatically persisted by Factorio.

- Can store: `nil`, strings, numbers, booleans, Factorio object references, tables of these.
- Cannot store: functions.
- To persist a table with a metatable, register it with `script.register_metatable()`.

## Game Startup Order

1. Run `control.lua` for every mod.
2. Is the mod new to the save? → `on_init` fires. Otherwise → `on_load` fires.
3. Has mod configuration changed? → `on_configuration_changed` fires.

## Runtime Events

- `on_init`: New game only. Initialize `storage` here (never at top-scope). Full access to `game` and `storage`.
- `on_load`: Save load only. **Do NOT write `storage` or access `game`.** Re-register event handlers and metatables here.
- `on_configuration_changed`: Mod version/config changed. Full access to `game` and `storage`.
