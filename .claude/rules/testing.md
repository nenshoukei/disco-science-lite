---
paths: ["spec/**/*.lua"]
---

# Testing

- Use `busted` for unit testing.
- Use `spec/helper.lua` for helper functions.
- Write tests in `spec/` as `<file_name>_spec.lua`.
- Run tests with `make test`.
- Use `assert.no_error(function () ... end)` for success pattern.
- Use `assert.is_not_nil(var) --- @cast var -nil` idiom for nil check.
