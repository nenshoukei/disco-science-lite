.PHONY: consts mods format typecheck test check check-updates graphics benchmark

consts:
	@lua tasks/update-consts.lua

mods:
	@tasks/update-all-mods.sh
	@uv run tasks/update-mod-description.py

format:
	@luafmt --write . --exclude "lua_modules/**" --exclude "vendor/**"

typecheck:
	@emmylua_check -c .luarc.json --ignore "lua_modules/**,vendor/**" .
	@tsc -p tasks/typecheck/tsconfig.json

test:
	@busted

check: consts mods format typecheck test

check-updates:
	@uv run tasks/check-updates/check-updates.py

graphics:
	@MOD=$(MOD) uv run tasks/graphics/update-graphics.py

benchmark:
	@echo "## Color Functions"
	@lua tasks/benchmark/color-functions.lua $(ARGS)
