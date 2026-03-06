# Code Style Guide

## Lua

- Based on Lua 5.2.1
- Follow `.editorconfig` for code formatting.
- Naming conventions:
    - constants should be `UPPER_CASE`.
    - local variables should be `lower_case`.
    - class names, module names and type names should be `UpperCamelCase`, except for `consts` and `utils`.
    - file names should be `lower-case.lua`.
- Do NOT define a global variable. Everything should be defined by `local`.
- Write comments in English.
- Write annotation comments for Lua Language Server.
    - Factorio data types are included by the editor extension.
- Variables without type inference should be explicitly typed with annotations. (@type, @class, ...)
- Functions should be explicitly typed with annotations. (@param, @return, ...)
- Prefer `arr[#arr + 1] = value` to append an element to an array than `table.insert()`.
- Prefer `for i = 1, #arr` to iterate an array than `for i, v in ipairs(arr)`.
- Do NOT use `#arr` on sparse tables.
- Define a local variable to access table fields to improve performance.
- Prefer `local function name()` to define a local function than `local name = function()`.
- Prefer `function table.name()` to define a method than `table.name = function()`.

## Factorio-specific Rules

- `pairs()` / `next()`: Iteration order is guaranteed to be insertion order. Keys inserted first are iterated first.
- `require()`: File path is based on the root of the project. `..` is not allowed.
- Global variables like `data`, `script`, `game`, `prototypes`, `helpers`, `storage` are defined by Factorio.
- Factorio supports multi-players, so all state in the game must be deterministic. Otherwise desync of state among players will happen.
- To print debug logs, use `log()` that prints logs to log files and debug console.

## Error Handling

- Always validate required parameters at the beginning of functions.
- Use `assert()` for development-time checks.
- Use `if condition then return end` for early returns.

## Testing

- Use `busted` for unit testing.
- Use `spec/helper.lua` for helper functions.
- Write tests in `spec/` as `<file_name>_spec.lua`.
- Run tests with `make test`.

## Performance

- Performance is always over readability. Especially for `on_tick` event.
- Cache frequently accessed table fields in local variables.
- Avoid expensive operations in `on_tick` event handlers.
- Batch operations when possible to reduce event frequency.
- Consider using `script.on_nth_tick()` for periodic tasks instead of every tick.
