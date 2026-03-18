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
- A `lab overlay` is an object that is rendered on a lab for colorizing it. One lab overlay for one lab.
- `lab overlay settings` is settings for rendering a lab overlay, specifying the overlay animation and scale. All values can be `nil` for the default settings.

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

- To run unit tests: `make test` or `busted spec/file-name_spec.lua`
- To lint: `make lint`
- To type-check `disco-science-lite.d.ts`: `make typecheck`
- To update graphics: `make graphics`
- To update constants in `consts.lua`: `make consts`
- To update mods list in `scripts/prototype/mods/_all.lua`: `make mods`
- To update and check codes: `make check` (runs `make consts`, `make mods`, `make lint`, `make test`, `make typecheck`)
  ma
