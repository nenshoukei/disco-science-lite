cache = true
max_line_length = false
max_code_line_length  = false
unused_args = false

include_files = {
    "*.lua",
    "scripts/**/*.lua",
    "spec/**/*.lua",
    "e2e/**/*.lua",
    "tasks/**/*.lua",
    "migrations/**/*.lua"
}
exclude_files = {
    "e2e/factorio-test-data-dir/**",
    "e2e/factorio-test.def.lua"
}

std = "lua52c"

files["spec/**/*_spec.lua"] = { std = "lua52+busted" }

files["e2e/*.lua"] = {
    std = "lua52+busted",
    globals = {
        "test",
        "after_ticks"
    }
}

globals = {
    "script",
    "game",
    "defines",
    "data",
    "serpent",
    "settings",
    "prototypes",
    "storage",
    "helpers",
    "log",
    "remote",
    "rendering",
    "commands",
    "mods",
    "util",
    "table_size",
    "debugadapter"
}
