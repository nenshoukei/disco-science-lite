"""Generate overlay graphics for Krastorio2 mod."""

import numpy as np
from PIL import Image

from lib import (
    ROOT_DIR,
    GRAPHICS_DIR,
    fill_black_background,
    extract_frame,
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

    frames_stack = np.stack([extract_frame(light, i, K2_GLOW_LIGHT_FRAME_W, K2_GLOW_LIGHT_FRAME_H, K2_GLOW_LIGHT_COLS) for i in range(K2_FRAMES)], axis=0)
    static_overlay = frames_stack.max(axis=0)
    static_overlay = np.clip(static_overlay * 0.8, 0, 255)
    save_image(Image.fromarray(static_overlay.astype(np.uint8), "L"), K2_OVERLAY_DST)
