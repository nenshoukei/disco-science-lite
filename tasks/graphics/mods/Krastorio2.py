"""Generate overlay graphics for Krastorio2 mod."""

import numpy as np
from PIL import Image

from lib import (
    ROOT_DIR,
    GRAPHICS_DIR,
    fill_black_background,
    extract_frame,
    resize_mask,
    open_mod_zip,
    save_image,
)

KRASTORIO2_ASSETS_SRC = ROOT_DIR.parent / "Krastorio2Assets_*.zip"

K2_ANIM_FRAME_W, K2_ANIM_FRAME_H = 520, 500
K2_ANIM_FRAME_SHIFT = (0, -0.1 * 64)  # shift = { 0.0, -0.1 }, scale=0.5 → tiles * 32 / 0.5

K2_GLOW_LIGHT_PATH = "buildings/singularity-lab/singularity-lab-glow-light.png"
K2_GLOW_LIGHT_FRAME_W, K2_GLOW_LIGHT_FRAME_H = 153, 117
K2_GLOW_LIGHT_FRAME_SHIFT = (0, -0.8 * 64)  # shift = { 0, -0.8 }, scale=0.5 → tiles * 32 / 0.5
K2_GLOW_LIGHT_COLS = 6

K2_FRAMES = 60

K2_DST_DIR = GRAPHICS_DIR / "Krastorio2"
K2_OVERLAY_DST = K2_DST_DIR / "singularity-lab-overlay.png"


def generate_krastorio2_images():
    with open_mod_zip(KRASTORIO2_ASSETS_SRC) as open_file:
        with open_file(K2_GLOW_LIGHT_PATH) as f:
            light_img = Image.open(f).convert("RGBA")

    light = np.array(fill_black_background(light_img).convert("L")).astype(np.float32)

    static_overlay = np.zeros((K2_ANIM_FRAME_H, K2_ANIM_FRAME_W), dtype=np.float32)
    for i in range(K2_FRAMES):
        light_frame = extract_frame(light, i, K2_GLOW_LIGHT_FRAME_W, K2_GLOW_LIGHT_FRAME_H, K2_GLOW_LIGHT_COLS)
        sized = resize_mask(light_frame, K2_ANIM_FRAME_W, K2_ANIM_FRAME_H, K2_ANIM_FRAME_SHIFT, K2_GLOW_LIGHT_FRAME_SHIFT)
        static_overlay = np.maximum(static_overlay, sized)

    static_overlay = np.clip(static_overlay * 0.8, 0, 255)
    save_image(Image.fromarray(static_overlay.astype(np.uint8), "L"), K2_OVERLAY_DST)
