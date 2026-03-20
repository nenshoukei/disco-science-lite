"""Generate overlay graphics for Hurricane lab sprites from Fusion lab mod."""

from pathlib import Path

import numpy as np
from PIL import Image

from lib import (
    ROOT_DIR,
    GRAPHICS_DIR,
    fill_black_background,
    rgb_to_grayscale,
    open_mod_zip,
    save_image,
)

FUSION_LAB_ZIP = ROOT_DIR.parent / "fusion-lab_*.zip"

HURRICANE_DST_DIR = GRAPHICS_DIR / "hurricane"
PHOTOMETRIC_LAB_RED_LIGHT_DST_1 = HURRICANE_DST_DIR / "photometric-lab-hr-red-light-1.png"
PHOTOMETRIC_LAB_RED_LIGHT_DST_2 = HURRICANE_DST_DIR / "photometric-lab-hr-red-light-2.png"
PHOTOMETRIC_LAB_OVERLAY_DST_1 = HURRICANE_DST_DIR / "photometric-lab-hr-overlay-1.png"
PHOTOMETRIC_LAB_OVERLAY_DST_2 = HURRICANE_DST_DIR / "photometric-lab-hr-overlay-2.png"


def generate_hurricane_images():
    def make_images(emission_img: Image.Image, red_light_dst: Path, overlay_dst: Path) -> None:
        emission = np.array(fill_black_background(emission_img)).astype(np.float32)
        r, g, b = emission[..., 0], emission[..., 1], emission[..., 2]
        grayscale = rgb_to_grayscale(r, g, b)

        # Extract red light
        red_light = r > (g + b)
        r = np.where(red_light, r, 0)
        g = np.where(red_light, g, 0)
        b = np.where(red_light, b, 0)
        mask = np.stack([r, g, b], axis=-1)
        save_image(Image.fromarray(mask.astype(np.uint8), "RGB"), red_light_dst)

        # Overlay: Grayscale
        overlay = np.clip(grayscale * 1.5, 0, 255)  # Brighten
        overlay[red_light] = 0  # Remove red light
        save_image(Image.fromarray(overlay.astype(np.uint8), "L"), overlay_dst)

    with open_mod_zip(FUSION_LAB_ZIP) as open_file:
        with open_file("graphics/entity/fusion-lab/photometric-lab-hr-emission-1.png") as f:
            emission_img1 = Image.open(f).convert("RGBA")
        make_images(emission_img1, PHOTOMETRIC_LAB_RED_LIGHT_DST_1, PHOTOMETRIC_LAB_OVERLAY_DST_1)

        with open_file("graphics/entity/fusion-lab/photometric-lab-hr-emission-2.png") as f:
            emission_img2 = Image.open(f).convert("RGBA")
        make_images(emission_img2, PHOTOMETRIC_LAB_RED_LIGHT_DST_2, PHOTOMETRIC_LAB_OVERLAY_DST_2)
