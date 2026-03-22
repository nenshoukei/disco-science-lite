# Disco Science Lite

Get those biolabs on the dance floor — with a performance twist.

Disco Science Lite is an unofficial variant of the beloved [Disco Science](https://mods.factorio.com/mod/DiscoScience) mod by Daniel Brauer, featuring algorithmic UPS optimizations and additional features including Biolabs support.

This mod is not officially affiliated with or endorsed by the original mod author.

## What It Does

Your science labs glow with the color of the science packs they're consuming — and the colors shift and pulse dynamically, disco-style. One glance at your factory floor tells you exactly what's being researched.

## Features

- **Performance**: Heavily optimized to keep UPS (Updates Per Second) impact minimal, even with large numbers of labs in mega-bases. Additional performance tuning options are available in mod settings. ([Technical details](docs/ups-optimization.md))

- **Space Age Support**: Biolabs from the Space Age DLC are supported out of the box, with a correctly fitted overlay animation for their unique shape.

- **Automatic Colorization for Unsupported Mods**: Any labs added by unsupported mods are automatically colorized too using a generic glow effect. This can be toggled in mod settings.

- **Color Customization**: Adjust color intensity through mod settings to get the brightness that suits your taste.

- **New Color Patterns**: In addition to the color patterns from the original mod, Disco Science Lite includes new ones that offer different visual rhythms and blending styles.

- **Mod API Compatibility**: Compatible with the original Disco Science mod's API, so mods supporting Disco Science should work out of the box.

If you are a modder, see the [full API reference](docs/api.md) for quick start examples and prototype/runtime stage APIs.

## Supported Mods

These mods are supported out of the box.

- [5Dim's mod - New Automatization](https://mods.factorio.com/mod/5dim_automation) by McGuten
- [AAI Industry](https://mods.factorio.com/mod/aai-industry) by Earendel
- [Bob's Tech](https://mods.factorio.com/mod/bobtech) by Bobingabout (including [Artisanal Reskins](https://mods.factorio.com/mod/reskins-bobs) by Kirazy)
- [Exotic Space Industries](https://mods.factorio.com/mod/exotic-space-industries) by eliont and PreLeyZero
- [Exotic Space Industries: Remembrance](https://mods.factorio.com/mod/exotic-space-industries-remembrance) by aRighteousGod
- [Factorio HD Age](https://mods.factorio.com/mod/factorio_hd_age_modpack) by Ingo_Igel
- [Krastorio 2](https://mods.factorio.com/mod/Krastorio2) by raiguard
- [Krastorio 2 Spaced Out](https://mods.factorio.com/mod/Krastorio2-spaced-out) by Polka_37
- [Lab-O-Matic](https://mods.factorio.com/mod/LabOMatic) by Stargateur
- [Pyanodons](https://mods.factorio.com/user/pyanodon) by pyanodon
- [Space Exploration](https://mods.factorio.com/mod/space-exploration) by Earendel (Space science lab is not colorized though)
- Space-Age Planet Mods
    - [Cerys](https://mods.factorio.com/mod/Cerys-Moon-of-Fulgora) by thesixthroc
    - [🌐Corrundum](https://mods.factorio.com/mod/corrundum) by Zach Kolansky
    - [🌐Metal and Stars](https://mods.factorio.com/mod/metal-and-stars) by Alex Boucher
    - [Moshine](https://mods.factorio.com/mod/Moshine) by snouz
    - [Muluna, Moon of Nauvis](https://mods.factorio.com/mod/planet-muluna) by Nicholas Gower
    - [Planet Castra](https://mods.factorio.com/mod/castra) by Bartz24
    - [Planet Maraxsis](https://mods.factorio.com/mod/maraxsis) by notnotmelon
    - [🌐Planet Rubia](https://mods.factorio.com/mod/rubia) by Loup&Snoop
    - [🌐Secretas&Frozeta](https://mods.factorio.com/mod/secretas) by Zach Kolansky

---

## Development

[Code Style Guide](/.claude/rules/code-style-guide.md)

Requirements: `lua`, `luarocks`, `pcre2`

This project's directory should be located in the `mods` directory of [Factorio's use data directory](https://wiki.factorio.com/Application_directory).

### Dependencies

To install dependencies by luarocks:

```
make dev
```

If you have installed `pcre2` with Homebrew at `/opt/homebrew`:

```
make dev C_INCLUDE_PATH=/opt/homebrew/include LIBRARY_PATH=/opt/homebrew/lib
```

### Tests

To run unit tests, lint, typecheck:

```
make check
```

This does:

- `make consts`: Updates constant values for special syntax (See below)
- `make mods`: Updates the [mod load list](/scripts/prototype/mods/_all.lua).
- `make lint`: Lints codes by `luacheck`
- `make test`: Runs unit tests by `busted`
- `make typecheck`: Type-checks [disco-science-lite.d.ts](disco-science-lite.d.ts) by `tsc`

### Special Constants Syntax

In order to maximize performance, we use special syntax which allows to embed constants as literal values like: `"abc"`, `123`, `true`, `false`.

Special syntax is `value --[[$CONST_NAME]]` where `value` is the literal value of the constant and `CONST_NAME` is the name of the constant. (For example, `print("xyz" --[[$ABC]])` uses `consts.ABC = "xyz"`)

- All constants are defined in [scripts/shared/consts.lua](scripts/shared/consts.lua).
- To use a constant, write `consts.CONST_NAME` to where you want (no require needed), and run `make consts`. It will be replaced by `value --[[$CONST_NAME]]`.
- To update a constant, change its value in [consts.lua](scripts/shared/consts.lua), and run `make consts`. All referrences to that constant will be updated idempotently.
- `make consts` targets all lua files in `scripts/` and `spec/`, and lua files on top-level such as `data.lua`.

### Graphic Generation

All image files under `graphics/` are auto-generated by the [Python script](/tasks/graphics/update-graphics.py). It can be executed by `make graphics`.

To generate these images, you have to install:

- Python 3 + uv
    - Required packgages can be installed with `uv sync`
- Factorio
- Space-Age DLC
- [Lab-O-Matic](https://mods.factorio.com/mod/LabOMatic) mod
    - This mod includes lab sprites from [BiusArt Lab graphics](https://mods.factorio.com/mod/laborat) mod which cannot be installed on recent Factorio versions.
- [Krastorio2Assets](https://mods.factorio.com/mod/Krastorio2Assets) mod
- [Fusion lab](https://mods.factorio.com/mod/fusion-lab) mod
    - This mod includes lab sprites from [Facotiro Buildings](https://shorturl.at/AFcDm) created by [Hurricane](https://mods.factorio.com/user/Hurricane046).

---

## Acknowledgements

Thanks to these amazing creators for their work:

- **[Daniel Brauer](https://mods.factorio.com/user/danielbrauer)** — for the original [Disco Science](https://mods.factorio.com/mod/DiscoScience) mod that started it all. _The disco must grow!_
- **[BiusArt](https://mods.factorio.com/user/BiusArt)** — for the graphics from [BiusArt Lab graphics](https://mods.factorio.com/mod/laborat).
- **[raiguard](https://mods.factorio.com/user/raiguard)** — for the graphics from [Krastorio 2](https://mods.factorio.com/mod/Krastorio2).
- **[Hurricane](https://mods.factorio.com/user/Hurricane046)** — for the graphics from [Factorio Buildings](https://shorturl.at/AFcDm).
- **[Zach Kolansky](https://mods.factorio.com/user/AnotherZach)** — for the graphics from [🌐Corrundum](https://mods.factorio.com/mod/corrundum).

## License

This mod includes code originally derived from the [Disco Science](https://mods.factorio.com/mod/DiscoScience) mod created by [Daniel Brauer](https://mods.factorio.com/user/danielbrauer), which is licensed under the MIT License.

The source code is released under the [MIT License](LICENSE).

Some image assets are derived from third-party works and are **NOT** covered by the MIT License:

| Files                                        | Source                                                        | Author                                                      | License                     |
| -------------------------------------------- | ------------------------------------------------------------- | ----------------------------------------------------------- | --------------------------- |
| [graphics/factorio/](graphics/factorio/)     | Factorio                                                      | Wube Software Ltd.                                          | © Wube Software Ltd. (EULA) |
| [graphics/laborat/](graphics/laborat/)       | [BiusArt Lab graphics](https://mods.factorio.com/mod/laborat) | [BiusArt](https://mods.factorio.com/user/BiusArt)           | GNU LGPL v3.0               |
| [graphics/Krastorio2/](graphics/Krastorio2/) | [Krastorio 2](https://mods.factorio.com/mod/Krastorio2)       | [raiguard](https://mods.factorio.com/user/raiguard)         | GNU LGPL v3.0               |
| [graphics/hurricane/](graphics/hurricane/)   | [Factorio Buildings](https://shorturl.at/AFcDm)               | [Hurricane](https://mods.factorio.com/user/Hurricane046)    | CC BY 4.0                   |
| [graphics/corrundum/](graphics/corrundum/)   | [🌐Corrundum](https://mods.factorio.com/mod/corrundum)        | [Zach Kolansky](https://mods.factorio.com/user/AnotherZach) | MIT                         |

See the `NOTICE.txt` and `LICENSE` files in each directory for details.
