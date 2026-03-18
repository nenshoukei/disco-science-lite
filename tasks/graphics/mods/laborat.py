"""Generate overlay graphics for LabOMatic (laborat) mod."""

from pathlib import Path

import numpy as np
from PIL import Image

from lib import (
    ROOT_DIR,
    GRAPHICS_DIR,
    fill_black_background,
    rgb_to_grayscale,
    extract_frame,
    make_mask_frame,
    open_mod_zip,
    save_image,
)

LABORAT_SRC = ROOT_DIR.parent / "LabOMatic_*.zip"
LABORAT_FRAME_W, LABORAT_FRAME_H = 150, 150
LABORAT_X4_FRAME_W, LABORAT_X4_FRAME_H = 600, 600
LABORAT_FRAMES = 30
LABORAT_COLS = 10

LABORAT_DST_DIR = GRAPHICS_DIR / "laborat"
LABORAT_MASK_DST = LABORAT_DST_DIR / "lab_albedo_anim-mask.png"
LABORAT_OVERLAY_DST = LABORAT_DST_DIR / "lab_albedo_anim-overlay.png"
LABORAT_X4_MASK_DST = LABORAT_DST_DIR / "lab_albedo_anim_x4-mask.png"
LABORAT_X4_OVERLAY_DST = LABORAT_DST_DIR / "lab_albedo_anim_x4-overlay.png"


def generate_laborat_images():
    def make_images(anim_img: Image.Image, light_img: Image.Image, frame_w: int, frame_h: int, modified_dst: Path, overlay_dst: Path) -> None:
        anim = np.array(fill_black_background(anim_img)).astype(np.float32)
        light = np.array(fill_black_background(light_img).convert("L")).astype(np.float32)

        # Blue tinted pixels => grayscale, other pixels => black
        r, g, b = anim[..., 0], anim[..., 1], anim[..., 2]
        blue_mask = b > 60
        overlay_grid = np.where(blue_mask, rgb_to_grayscale(r, g, b), 0)

        # Blend light in additive mode
        overlay_grid = np.clip(overlay_grid + light, 0, 255)

        # Static overlay: minimum brightness across all frames, independent of entity animation.
        # Overlay animation cannot be synchronized with entity animation (rendering.draw_animation
        # starts from the current tick offset, not frame 0), so we use a single static frame.
        frames_stack = np.stack([extract_frame(overlay_grid, i, frame_w, frame_h, LABORAT_COLS) for i in range(LABORAT_FRAMES)], axis=0)
        static_overlay = frames_stack.min(axis=0).clip(0, 90)  # Clipping makes pixels inside the dome flat
        static_overlay = np.clip(static_overlay * 1.5, 0, 255)  # Brighten
        save_image(Image.fromarray(static_overlay.astype(np.uint8), "L"), overlay_dst)

        mask = make_mask_frame(anim.astype(np.uint8), overlay_grid > 10)
        save_image(Image.fromarray(mask, "LA"), modified_dst)

    with open_mod_zip(LABORAT_SRC) as open_file:
        with open_file("graphics/lab_albedo_anim.png") as f:
            anim_img = Image.open(f).convert("RGBA")
        with open_file("graphics/lab_light_anim.png") as f:
            light_img = Image.open(f).convert("RGBA")
        make_images(anim_img, light_img, LABORAT_FRAME_W, LABORAT_FRAME_H, LABORAT_MASK_DST, LABORAT_OVERLAY_DST)

        with open_file("graphics/lab_albedo_anim_x4.png") as f:
            anim_img_x4 = Image.open(f).convert("RGBA")
        with open_file("graphics/lab_light_anim_x4.png") as f:
            light_img_x4 = Image.open(f).convert("RGBA")
        make_images(anim_img_x4, light_img_x4, LABORAT_X4_FRAME_W, LABORAT_X4_FRAME_H, LABORAT_X4_MASK_DST, LABORAT_X4_OVERLAY_DST)
