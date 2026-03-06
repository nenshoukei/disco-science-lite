cache = true
max_line_length = false
max_code_line_length  = false
unused_args = false

std = "lua52c"
files["spec/**/*_spec.lua"] = { std = "lua52+busted" }

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
}
