---
paths: ["**/*.lua"]
---

# Code Style Guide

## Lua

- Based on Lua 5.2.1
- Follow `.editorconfig` for code formatting.
- Naming conventions:
    - constants should be `UPPER_CASE`.
    - local variables should be `lower_case`.
    - class names, module names and type names should be `UpperCamelCase`, except for `consts`.
    - file names should be `lower-case.lua`.
    - unit test file names should be `lowe-case_spec.lua`.
- Do NOT define a global variable. Everything should be defined by `local`.
- Write comments in English.
- Write annotation comments for Lua Language Server. Annotation comments start with `--- `.
    - Factorio data types are included by the editor extension.
    - Functions should be explicitly typed with annotations. (`@param`, `@return`, ...)
    - Variables without type inference should be explicitly typed with annotations. (`@type`, `@class`, ...)
    - Use `@class (exact) StructClass` to define a struct. `(exact)` makes it incapable of extra keys.
    - Always specify key and value types for tables, like `@type table<string, boolean>`.
    - Do NOT use `@type any`.
    - Use `@cast var_name TypeName` or `expression --[[@as TypeName]]` for type casting.
    - Use `@cast var_name -nil` for removing `nil` from var_name's type union.
- Prefer `arr[#arr + 1] = value` to append an element to an array than `table.insert()`.
- Prefer `for i = 1, #arr` to iterate an array than `for i, v in ipairs(arr)`.
- Prefer `local function name()` to define a local function than `local name = function()`.
- Prefer `function table.name()` to define a method than `table.name = function()`.
- Prefer early returns by using `if condition then return end`.

## Factorio-specific Rules

- `pairs()` / `next()`: Iteration order is guaranteed to be insertion order. Keys inserted first are iterated first.
- `require()`: File path is based on the root of the project. `..` is not allowed.
    - Use `.` for directory separators, like `require("scripts.shared.consts")`.
- Global variables like `data`, `script`, `game`, `prototypes`, `helpers`, `storage` are defined by Factorio.
- Factorio supports multi-players, so all state in the game must be deterministic. Otherwise desync of state among players will happen.
- To print debug logs, use `log()` that prints logs to log files and debug console.

## Testing

- Always write unit tests, excpet for ones heavily depending on Factorio API.
- Use `busted` for unit testing.
- Use `spec/helper.lua` for helper functions.
- Write tests in `spec/` as `<file_name>_spec.lua`.
- Run tests with `make test`.
- Use `assert.no_error(function () ... end)` for success pattern.
- Use `assert.is_not_nil(var) --- @cast var -nil` idiom for nil check.

## Performance

- Performance is always over readability. Especially for `on_tick` event.
- Cache frequently accessed table fields in local variables.
