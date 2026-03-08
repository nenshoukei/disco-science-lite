# Project Overview

This project is to create a mod for Factorio, a game about factories. Written in Lua.

## Features

This mod provides users with:

- Colorization of science labs
    - A science lab is an entity that researches technologies by consuming science packs.
    - The color is chosen from the color of science packs, so that the user can distinguish the science pack being consumed.
    - Also, the color will change dynamically like a "disco", calculated by color functions.

## Special Terms

- A `research ingredient` is an ingredient consumed by labs for reasearching technologies. One technology has 0+ ingredients. In vanilla Factorio, the ingredients are called "science packs".
- A `color function` is a function that calculates colors of labs. This calculation chooses a color from the colors of research ingredients, and changes it by a formula.
- A `lab overlay` is an object that is rendered on a lab for colorizing it. One lab overlay for one lab.
- A `lab registration` is a record that registers a lab type with this mod, specifying the overlay animation and scale.

## Directory Structure

- `locale/` - Localization files.
- `graphics/` - Graphic files.
- `scripts/` - Lua scripts.
    - `prototype/` - For Prototype stage.
    - `runtime/` - For Runtime stage.
    - `settings/` - For Settings stage.
    - `shared/` - Shared scripts used by multiple stages.
- `migrations/` - Migration files.
- `spec/` - Unit tests.
- `*.lua` - Entrypoints of Factorio mod.

## Commands

To run unit tests:

```
make test
```

To lint:

```
make lint
```

To update graphics:

```
make graphics
```
