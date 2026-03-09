# Key Concepts in Factorio

## Stages

Factorio has three stages at game startup and during game.

On each stage, top-level lua files for that stage are loaded and run by Factorio.

- Settings stage: Runs `settings.lua`, `settings-updates.lua` then `settings-final-fixes.lua` to define the mod's settings by `data:extend()`.
- Prototype stage: Runs `data.lua`, `data-updates.lua` then `data-final-fixes.lua` to define the mod's prototypes by `data:extend()`.
- Runtime stage: Runs `control.lua` to control the mod's behavior on the game runtime.

Each file on every mod runs in order of dependency or mod name sort.

To modify other mod's definitions, adding the mod to `dependencies` in `info.json` ensures correct load order. If no specific mod is a target, use `[stage]-updates.lua` or `[stage]-final-fixes.lua` to delay the modification.

## Settings

- Each mod can define the mod's settings on settings stage.
- The settings can be changed by the user in Settings GUI by Factorio.
- Settings have three types:
    - `startup`: This kind of setting is available in the prototype stage, and can not be changed runtime. They have to be set to the same values for all players on a server.
    - `runtime-global`: This kind of setting is global to an entire save game and can be changed runtime. On servers, only admins can change these settings.
    - `runtime-per-user`: This kind of setting is only available runtime in the control.lua stage and each player has their own instance of this setting. When a player joins a server their local setting of "keep mod settings per save" determines if the local settings they have set are synced to the loaded save or if the save's settings are used.

## Prototype

- Prototypes are used as templates for the items, entities, recipes, etc. in the game engine.
- Prototype definitions are typed as `data.XxxPrototype` and prototypes on runtime are typed as `LuaXxxPrototype`, where `Xxx` is type of prototype.
- On Prototype stage, all prototype definitions can be accessed through `data.raw` like `data.raw["item"]["xxx"]`.
