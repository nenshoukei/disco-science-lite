# Factorio Mod Guide

This guide provides an overview of Factorio mod development.

## Prototypes

- Prototypes are used as templates for the items, entities, recipes, etc. in the game engine.
- Prototype definitions are typed as `data.XxxPrototype` and prototypes on runtime are typed as `LuaXxxPrototype`, where `Xxx` is type of prototype.
- On Prototype stage, all prototype definitions can be accessed through `data.raw` like `data.raw["item"]["xxx"]`.

## Data Lifecycle

Factorio has three stages at game startup and during runtime.

On each stage, top-level lua files for that stage (`[stage].lua`, `[stage]-updates.lua`, `[stage]-final-fixes.lua`) are loaded and run by Factorio.

- Settings stage: `settings.lua` or `settings-*.lua` to define the mod's settings by `data:extend()`.
- Prototype stage: `data.lua` or `data-*.lua` to define the mod's prototypes by `data:extend()`.
- Runtime stage: `control.lua` or `control-*.lua` to control the mod's behavior on the game runtime.

Each file on every mod runs in order of dependency or mod name sort. So, other mod's data at the same stage can be modified by using `[stage]-updates.lua` or `[stage]-final-fixes.lua`.

## Game Startup

At game startup, including loading a game, Factorio runs following steps:

1. Run `control.lua`, `control-updates.lua`, `control-final-fixes.lua` for every mods.
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

## Migrations

Migrations are a way to fix up a save file which was used in an older version of the game or mod. They have to be either `.lua` or `.json` files in the mod's `migrations` folder, depending on their purpose. They are typically used to change the type of a prototype or correct research and recipe states after changes.

### JSON migrations

JSON migrations allow changing one prototype into another. This is typically used to rename a prototype.

Note that when an entity prototype's name is changed, the entity retains its previous unit_number and any references to the entity saved in storage stay valid. Changing an entity's type will however result in a new unit_number and an invalid entity reference in storage.

When changing a prototype's type or name with a migration, any references to the prototype saved in storage will stay valid. When a prototype is removed, any references to it saved in storage will also become invalid.

JSON migrations are applied as a map is being loaded. Multiple such migrations can be applied at once. All JSON migrations are applied before any Lua migrations.

#### JSON Example

The "wall" entity and item being renamed to "stone-wall":

```json
{
    "entity": [["wall", "stone-wall"]],
    "item": [["wall", "stone-wall"]]
}
```

### Lua migrations

Lua migrations allow altering the loaded game state before it starts running. The global `game` object is available in Lua migrations, which is how the game state can be modified.

The game resets recipes and technologies any time mods, prototypes, or startup settings change, so this does not need to be done by migration scripts anymore.

## Storage

On runtime, the global `storage` is a table which is automatically persisted by Factorio on save/load the game.

- It is per-mod. So keys are not conflicted with other mods.
- It can only store:
    - basic data: `nil`, strings, numbers, booleans
    - references to objects returned by the game function.
    - tables of above types.
- To persist a table with a metatable, that metatable should be registered by `script.register_metatable()` to restore on unserialization.
- Functions are not allowed in `storage`.

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

## GUI

- All GUI elements are represented as `LuaGuiElement` object in Factorio.
- `element.tags` table can be used to store custom data for the element.
    - Only basic data types (`string`, `boolean`, `number` and `table` of basic data types) are allowed.
    - Numeric keys on sparse table are converted to strings. (`[1]` becomes `["1"]`).
- Setting a string to `element.style` sets the style from `gui-style` prototype by the string key.
    - There is only one `gui-style` prototype in the game. Predefined by Factorio.
    - Accessing to `element.style` returns the style object `LuaStyle`.
- Events on GUI elements can be subscribed by `script.on_event()` with event type like `defines.events.on_gui_click`.
    - Event handler receives `event` object with `element` property that points to the GUI element.

## Localization

- All strings displayed on Factorio must be localized. Otherwise, `missing key: ...` is displayed instead.
- Localization files are stored in `locale/[lang]/[filename].cfg`.
- Localization files are INI-format files, where `[section]` is the namespace and `key=value` is the localization entry.
- A localized string is represented as `{ "namespace.key" }` in Lua code.
- Parameters can be used in localization strings as `__1__`, `__2__`, ... syntax, and `{ "namespace.key", parameter1, parameter2 }` in Lua code.
- Plural format can be used like `format-days=__1__ __plural_for_parameter_1__{1=day|rest=days}`, which results in `1 day` and `2 days`.
    - Plural format can contain other keys like `__plural_for_parameter__1__{1=__1__ player is|rest=__1__ players are}__ connecting`, which results in `1 player is connecting` and `2 players are connecting`.
- Concatenating localised strings can be done by an array with an empty string at first like `{ "", { "namespace.key1" }, { "namespace.key2" } }`.
- Some built-in placeholders are provided by Factorio:
    - `__1__`, `__2__`, ... for parameters
    - `__CONTROL_LEFT_CLICK__` for left mouse button, or B button on controller.
    - `__CONTROL_RIGHT_CLICK__` for right mouse button, or X button on controller.
    - `__CONTROL__[name]__` for custom input bindings for name, where name is `CustomInputPrototype.name`.

## Inter-mod Communication

For inter-mod communication, the global `remote` object is provided.

Example:

```lua
-- Mod A
remote.add_interface("mod-A", {
    hello = function ()
        print("mod-A.hello is called")
    end,
    test = function (arg1, arg2)
        print("mod-A.test is called with " .. arg1 .. " and " .. arg2)
    end
})

-- Mod B
remote.call("mod-A", "hello") -- prints "mod-A.hello is called"
remote.call("mod-A", "test", "ABC", 123) -- prints "mod-A.test is called with ABC and 123"
```
