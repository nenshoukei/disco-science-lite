---
paths: ["migrations/**"]
---

# Migrations

Migrations are a way to fix up a save file which was used in an older version of the game or mod. They have to be either `.lua` or `.json` files in the mod's `migrations` folder, depending on their purpose. They are typically used to change the type of a prototype or correct research and recipe states after changes.

## JSON migrations

JSON migrations allow changing one prototype into another. This is typically used to rename a prototype.

Note that when an entity prototype's name is changed, the entity retains its previous unit_number and any references to the entity saved in storage stay valid. Changing an entity's type will however result in a new unit_number and an invalid entity reference in storage.

When changing a prototype's type or name with a migration, any references to the prototype saved in storage will stay valid. When a prototype is removed, any references to it saved in storage will also become invalid.

JSON migrations are applied as a map is being loaded. Multiple such migrations can be applied at once. All JSON migrations are applied before any Lua migrations.

### JSON Example

The "wall" entity and item being renamed to "stone-wall":

```json
{
    "entity": [["wall", "stone-wall"]],
    "item": [["wall", "stone-wall"]]
}
```

## Lua migrations

Lua migrations allow altering the loaded game state before it starts running. The global `game` object is available in Lua migrations, which is how the game state can be modified.

The game resets recipes and technologies any time mods, prototypes, or startup settings change, so this does not need to be done by migration scripts anymore.
