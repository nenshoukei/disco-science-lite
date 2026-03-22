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
- Prefer `for i = 1, #arr` to iterate an array than `for i, v in ipairs(arr)`.
- Prefer `local function name()` to define a local function than `local name = function()`.
- Prefer `function table.name()` to define a method than `table.name = function()`.
- Prefer early returns by using `if condition then return end`.
- Performance is always over readability. Especially for hot paths.

## Factorio-specific Rules

- `pairs()` / `next()`: Iteration order is guaranteed to be insertion order. Keys inserted first are iterated first.
- `require()`: File path is based on the root of the project. `..` is not allowed.
    - Use `.` for directory separators, like `require("scripts.shared.consts")`.
- Global variables like `data`, `script`, `game`, `prototypes`, `helpers`, `storage` are defined by Factorio.
- Factorio supports multi-players, so all state in the game must be deterministic. Otherwise desync of state among players will happen.
- To print debug logs, use `log()` that prints logs to log files and debug console.

## Special Syntax for Constants

- In order to maximize performance, we use special syntax which allows to embed constants as literal values like: `"abc"`, `123`, `true`, `false`.
- Special syntax is `value --[[$expr]]` where `value` is the pre-evaluated literal and `expr` is a Lua expression evaluated in the `consts` scope.
- These constants are defined in [consts.lua](../../scripts/shared/consts.lua).
- Examples:
    - `"xyz" --[[$ABC]]` — simple constant reference: `consts.ABC = "xyz"`
    - `"mks-dsl-foo" --[[$NAME_PREFIX .. "foo"]]` — expression: `consts.NAME_PREFIX .. "foo"` evaluated at `make consts` time
- To use a constant, write `consts.CONST_NAME` to where you want (no require needed), and run `make consts`. It will be replaced by `value --[[$CONST_NAME]]`.
- To use a constant expression, write the expression as `value --[[$expr]]` directly, or let `make consts` replace `consts.CONST_NAME` first and then extend the expression manually.
- To update a constant, change its value in `consts.lua`, and run `make consts`. All references to that constant will be updated idempotently.
- `make consts` targets all lua files in `scripts/` and `spec/`, and lua files on top-level such as `data.lua`.

## Testing

- Always write unit tests, excpet for ones heavily depending on Factorio API.
- Use `busted` for unit testing. Run `make test` or `busted spec/file-name_spec.lua` for running unit tests.
- Use [spec/helper.lua](../../spec/helper.lua) for helper functions.
- Write tests in `spec/` as `<file_name>_spec.lua`.
- Use `assert.no_error(function () ... end)` for success pattern.
- Use `assert.is_not_nil(var) --- @cast var -nil` idiom for nil check.
