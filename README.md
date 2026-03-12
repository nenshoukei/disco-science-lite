# Disco Science Lite

Get those biolabs on the dance floor — with a performance twist.

Disco Science Lite is a variant of the beloved [Disco Science](https://mods.factorio.com/mod/DiscoScience) mod by Daniel Brauer, featuring algorithmic UPS optimizations and additional features including Space Age support.

## What It Does

Your science labs glow with the color of the science packs they're consuming — and the colors shift and pulse dynamically, disco-style. One glance at your factory floor tells you exactly what's being researched.

## Features

### Performance

Heavily optimized to keep UPS (Updates Per Second) impact minimal, even with large numbers of labs. Additional performance tuning options are available in mod settings. ([Technical details](docs/ups-optimization.md))

### Space Age Support

Biolabs from the Space Age DLC are supported out of the box, with a correctly fitted overlay animation for their unique shape.

### Colorize any labs added by unsupported mods

Any labs added by unsupported mods are automatically colorized too using a generic glow effect. This can be toggled in mod settings.

### Color Customization

Adjust color intensity through mod settings to get the brightness that suits your taste.

### New Color Patterns

In addition to the color patterns from the original mod, Disco Science Lite includes new ones that offer different visual rhythms and blending styles.

### Mod API Compatibility

The runtime API is compatible with the original Disco Science mod, so other mods that integrate with Disco Science work out of the box.

---

## API for Mod Authors

See [docs/api.md](docs/api.md) for the full API reference, including quick start examples, prototype stage and runtime stage APIs, and type definition files for Lua Language Server and TypeScriptToLua.

---

## Development

[Code Style Guide](/.claude/rules/code-style-guide.md)

Requirements: `lua`, `luarocks`, `pcre2`

To install dependencies by luarocks:

```
make dev
```

If you have installed `pcre2` with Homebrew:

```
make dev C_INCLUDE_PATH=/opt/homebrew/include LIBRARY_PATH=/opt/homebrew/lib
```

To lint:

```
make lint
```

To run unit tests:

```
make test
```

To update the constants defined in [consts.lua](./scripts/shared/consts.lua):

```
make consts
```

To type-check `disco-science-lite.d.ts` (requires `tcs`):

```
make typecheck
```

To update image files (requires `python` with Anaconda, Factorio, Space-Age DLC):

```
make graphics
```

## License

The original [Disco Science](https://mods.factorio.com/mod/DiscoScience) mod was created by Daniel Brauer and is licensed under the [MIT License](LICENSE).

This mod is a modified version of the original and is likewise released under the MIT License.

The image files under `graphics/` were generated based on official Factorio assets.
