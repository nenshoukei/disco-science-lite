---
paths: ["locale/**"]
---

# Localization

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
