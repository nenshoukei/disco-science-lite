.PHONY: dev lint test typecheck consts graphics

dev:
	# If pcre2 is installed by Homebrew
	# make dev C_INCLUDE_PATH=/opt/homebrew/include LIBRARY_PATH=/opt/homebrew/lib
	luarocks install --deps-only disco-science-lite-dev-1.rockspec

lint:
	luacheck .

test:
	busted

typecheck:
	tsc -p types-test/tsconfig.json

consts:
	lua tasks/update-consts.lua

graphics:
	python tasks/update-graphics.py
