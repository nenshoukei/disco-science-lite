---
paths: ["control*.lua", "scripts/runtime/**/*.lua"]
---

# Runtime

## Entity

- Entities are everything that exists on the map except for tiles.
- If a player places an item like labs, machines, transport belts, etc. on the ground, it will become an entity.
- All entities have their own `unit_number`, which is a unique identifiying number for the lifetime of the save. These are allocated sequentially, and not re-used (until overflow).

## Storage

On runtime, the global `storage` is a table which is automatically persisted by Factorio on save/load the game.

- It is per-mod. So keys are not conflicted with other mods.
- It can only store:
    - basic data: `nil`, strings, numbers, booleans
    - references to objects returned by the game function.
    - tables of above types.
- To persist a table with a metatable, that metatable should be registered by `script.register_metatable()` to restore on unserialization.
- Functions are not allowed in `storage`.

## Game Startup

At game startup, including loading a game, Factorio runs following steps:

1. Run `control.lua` for every mods.
2. Is the mod new to the save?
    - Yes:
        - `on_init` event fires.
        - Migrations
    - No:
        - Migrations
        - `on_load` event fires.
3. Has the mod configuration changed?
    - Yes:
        - `on_configuration_changed` event fires.
4. Startup done.

## Runtime events

On runtime, there are several events can be hooked:

- `script.on_init()` handlers are called on starting a new game. Not at save/load the game.
    - `storage` should be initialized in this event handler. Never be on top-scope.
    - It has full access to `game` and `storage`.
- `script.on_load()` handlers are called on loading the game. Not at starting a new game.
    - Game state like `storage` must not be changed on this event. Otherwise desyncs happen.
    - Access to `game` is not available. Reading `storage` is allowed, but not writing.
    - Event handlers should be registered again by `script.on_event()`. (Not serialized)
    - The only legitimate uses of this event are these:
        - Re-setup metatables not registered with `script.register_metatable()`, as they are not persisted through the save/load cycle.
        - Re-setup event handlers.
        - Create local references to data stored in `storage`.
- `script.on_configuration_changed()` handlers are called when the mod configuration changed, including mod version changes.
    - It is also called after `on_load` when Mod startup settings changed in Factorio title screen.
    - It has full access to `game` and `storage`.
