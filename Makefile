FACTORIO_DATA := $(HOME)/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/data

.PHONY: dev lint test graphics

dev:
	luarocks install --deps-only disco-science-lite-dev-1.rockspec

lint:
	luacheck .

test:
	busted

graphics:
	convert "$(FACTORIO_DATA)/base/graphics/entity/lab/lab-light.png" \
		-colorspace Gray -auto-level \
		graphics/lab-overlay.png
	convert "$(FACTORIO_DATA)/space-age/graphics/entity/biolab/biolab-lights.png" \
		-colorspace Gray -level "0,50%,2.0" \
		graphics/biolab-overlay.png
