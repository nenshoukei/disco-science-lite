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
    def make_images(anim_img: Image.Image, light_img: Image.Image, frame_w: int, frame_h: int, mask_dst: Path, overlay_dst: Path) -> None:
        anim = np.array(fill_black_background(anim_img)).astype(np.float32)
        light = np.array(fill_black_background(light_img).convert("L")).astype(np.float32)

        # Blue tinted pixels => desaturate, other pixels => keep original
        mask = anim.copy()
        r, g, b = mask[..., 0], mask[..., 1], mask[..., 2]
        dome_mask = b > 55
        grayscale = rgb_to_grayscale(r, g, b)
        contrast = 1.5
        gray_c = np.clip((grayscale - 127) * contrast + 128, 0, 255)
        desaturate = 0.8
        darken = 0.6
        r[dome_mask] = (r[dome_mask] * (1 - desaturate) + gray_c[dome_mask] * desaturate) * darken
        g[dome_mask] = (g[dome_mask] * (1 - desaturate) + gray_c[dome_mask] * desaturate) * darken
        b[dome_mask] = (b[dome_mask] * (1 - desaturate) + gray_c[dome_mask] * desaturate) * darken
        save_image(Image.fromarray(mask.clip(0, 255).astype(np.uint8), "RGBA"), mask_dst)

        # Extract dome pixels
        extracted = np.where(dome_mask, grayscale, 0)
        # Flatten pixels inside dome
        extracted = extracted.clip(0, 80) / 80 * 200
        # Apply fade animation
        for i in range(LABORAT_FRAMES):
            frame = extract_frame(extracted, i, frame_w, frame_h, LABORAT_COLS)
            frame[:, :] = frame[:, :] * (0.75 - 0.25 * np.cos(2 * np.pi * i / LABORAT_FRAMES))
        # Additive blend light image
        extracted = np.clip(extracted + light, 0, 255)
        save_image(Image.fromarray(extracted.astype(np.uint8), "L"), overlay_dst)

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
