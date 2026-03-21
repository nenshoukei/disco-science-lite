"""Generate overlay graphics for Corrundum mod."""

from PIL import Image

from lib import (
    ROOT_DIR,
    GRAPHICS_DIR,
    open_mod_zip,
    save_image,
)

CORRUNDUM_ZIP = ROOT_DIR.parent / "corrundum_*.zip"

CORRUNDUM_DST_DIR = GRAPHICS_DIR / "corrundum"
SMOKE_INNER_DST = CORRUNDUM_DST_DIR / "chemical-plant-smoke-inner-grayscaled.png"
SMOKE_OUTER_DST = CORRUNDUM_DST_DIR / "chemical-plant-smoke-outer-grayscaled.png"


def generate_corrundum_images():
    CORRUNDUM_DST_DIR.mkdir(parents=True, exist_ok=True)

    with open_mod_zip(CORRUNDUM_ZIP) as open_file:
        for src_path, dst_path in [
            ("graphics/entity/chemical-plant-smoke-inner-blue.png", SMOKE_INNER_DST),
            ("graphics/entity/chemical-plant-smoke-outer-blue.png", SMOKE_OUTER_DST),
        ]:
            with open_file(src_path) as f:
                img = Image.open(f).convert("RGBA")
            save_image(img.convert("LA"), dst_path)
