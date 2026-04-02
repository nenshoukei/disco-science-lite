.PHONY: dev lint test typecheck consts graphics mods mod-description benchmark check full-check

dev:
	# If pcre2 is installed by Homebrew
	# make dev C_INCLUDE_PATH=/opt/homebrew/include LIBRARY_PATH=/opt/homebrew/lib
	@luarocks install --deps-only disco-science-lite-dev-1.rockspec

lint:
	@luacheck --formatter plain .
	@uv run ruff check

test:
	@busted

consts:
	@lua tasks/update-consts.lua

graphics:
	@MOD=$(MOD) uv run tasks/graphics/update-graphics.py

mod-description:
	@uv run tasks/update-mod-description.py

mods:
	@tasks/update-all-mods.sh

check: consts mods mod-description lint test

typecheck:
	@tsc -p tasks/typecheck/tsconfig.json
	@lua-language-server --check_format=pretty --configpath=.vscode/settings.json --check=.

full-check: check typecheck

benchmark:
	@echo "## Color Functions"
	@lua tasks/benchmark/color-functions.lua $(ARGS)
