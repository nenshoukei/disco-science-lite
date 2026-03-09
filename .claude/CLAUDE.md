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
- A `color function` is a function that calculates colors of labs. This calculation chooses a color from the colors of research ingredients, and changes it by a formula.
- A `lab overlay` is an object that is rendered on a lab for colorizing it. One lab overlay for one lab.
- `lab overlay settings` is settings for rendering a lab overlay, specifying the overlay animation and scale. All values can be `nil` for the default settings.

## Directory Structure

- `docs/` - Documentation.
- `graphics/` - Graphic files.
- `locale/` - Localization files.
- `mod-portal/` - Files for Factorio mod portal.
- `scripts/` - Lua scripts.
    - `prototype/` - For Prototype stage.
    - `runtime/` - For Runtime stage.
    - `settings/` - For Settings stage.
    - `shared/` - Shared scripts used by multiple stages.
- `migrations/` - Migration files.
- `spec/` - Unit tests.
- `types-test/` - Test files for `make typecheck`.
- `*.lua` - Entrypoints of Factorio mod.

## Commands

- To run unit tests: `make test`
- To lint: `make lint`
- To type-check `disco-science-lite.d.ts`: `make typecheck`
- To update graphics: `make graphics`
