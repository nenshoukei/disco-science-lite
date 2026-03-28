# Project Overview

This project is to create a mod for Factorio, a game about factories. Written in Lua.

## Features

This mod provides users with:

- Colorization of science labs
    - A science lab is a facility for researching technologies by consuming science packs.
    - The color is chosen from the color of science packs, so that the user can distinguish which science pack is being consumed.
    - Also, the color will change dynamically like a "disco", calculated by color functions.

## Special Terms

- A `research ingredient` is an ingredient consumed by labs for reasearching technologies. One technology has 0+ ingredients. In vanilla Factorio, the ingredients are called "science packs".
- A `color function` is a function that calculates colors of labs. This calculation chooses a color from the colors of research ingredients, and changes it by a formula. Defined in `scripts/runtime/color-functions.lua`.
- An `overlay` is an object that is rendered on a lab for colorizing it. One overlay for one lab.
- A `companion` is an object that is rendered above or beneath the overlay, to provide a non-colorized layer that is animated in sync with the overlay. Same lifecycle as the overlay. One overlay has zero or one companion.

## Directory Structure

- `docs/` - Documentation.
- `graphics/` - Graphic files.
- `locale/` - Localization files.
- `scripts/` - Lua scripts.
    - `prototype/` - For Prototype stage.
    - `runtime/` - For Runtime stage.
    - `settings/` - For Settings stage.
    - `shared/` - Shared scripts used by multiple stages.
- `migrations/` - Migration files.
- `spec/` - Unit tests.
- `tasks/` - Executables and configurations for make tasks.
- `*.lua` - Entrypoints of Factorio mod.

## Commands

- `make check`: Runs following: (very fast)
    - `make consts`: Updates constant values for the special syntax
    - `make mods`: Updates the [mod load list](/scripts/prototype/mods/_all.lua)
    - `make mod-description`: Updates the [mod description](/docs/mod-portal/description.md)
    - `make lint`: Lints codes by `luacheck`
    - `make test`: Runs unit tests by `busted`
- `make full-check`: Runs following: (approx. 30 seconds to run)
    - `make check`
    - `make typecheck`: Type-checks by lua-language-server, and checks [disco-science-lite.d.ts](/disco-science-lite.d.ts) by `tsc`
- `make graphics`: Updates graphics
- `make graphics MOD=mod-name`: Updates mod-name graphics only
