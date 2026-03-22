"""Generate overlay graphics for Hurricane lab sprites from Fusion lab mod."""

from pathlib import Path

import numpy as np
from PIL import Image

from lib import (
    ROOT_DIR,
    GRAPHICS_DIR,
    fill_black_background,
    extract_frame,
    assemble_grid,
    rgb_to_grayscale,
    open_mod_zip,
    save_image,
)

FUSION_LAB_ZIP = ROOT_DIR.parent / "fusion-lab_*.zip"
FRAMES_1 = 64
FRAMES_2 = 16
COLS = 8
FRAME_W, FRAME_H = 330, 390

HURRICANE_DST_DIR = GRAPHICS_DIR / "hurricane"
PHOTOMETRIC_LAB_RED_LIGHT_DST_1 = HURRICANE_DST_DIR / "photometric-lab-hr-red-light-1.png"
PHOTOMETRIC_LAB_RED_LIGHT_DST_2 = HURRICANE_DST_DIR / "photometric-lab-hr-red-light-2.png"
PHOTOMETRIC_LAB_OVERLAY_DST_1 = HURRICANE_DST_DIR / "photometric-lab-hr-overlay-1.png"
PHOTOMETRIC_LAB_OVERLAY_DST_2 = HURRICANE_DST_DIR / "photometric-lab-hr-overlay-2.png"
PHOTOMETRIC_LAB_MASK_DST_1 = HURRICANE_DST_DIR / "photometric-lab-hr-mask-1.png"
PHOTOMETRIC_LAB_MASK_DST_2 = HURRICANE_DST_DIR / "photometric-lab-hr-mask-2.png"


def generate_hurricane_images():
    def make_images(animation_img: Image.Image, emission_img: Image.Image, red_light_dst: Path, overlay_dst: Path, mask_dst: Path, frame_count: int) -> None:
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

        # Calculate mask pixels by stacking overlay frames
        overlay_stack = np.stack([extract_frame(overlay, i, FRAME_W, FRAME_H, COLS) for i in range(frame_count)], axis=0)
        mask_pixels = (overlay_stack.max(axis=0) > 10)[..., np.newaxis]

        # Extract mask pixels from animation
        animation = np.array(animation_img).astype(np.uint8)
        trasparent = np.zeros((FRAME_H, FRAME_W, 4), dtype=np.uint8)
        frames = []
        for i in range(frame_count):
            frame = extract_frame(animation, i, FRAME_W, FRAME_H, COLS)
            frame = np.where(mask_pixels, frame, trasparent)
            frames.append(frame)

        grid = assemble_grid(frames, COLS)
        save_image(Image.fromarray(grid.astype(np.uint8), "RGBA"), mask_dst)

    with open_mod_zip(FUSION_LAB_ZIP) as open_file:
        with open_file("graphics/entity/fusion-lab/photometric-lab-hr-animation-1.png") as f:
            animation_img1 = Image.open(f).convert("RGBA")
        with open_file("graphics/entity/fusion-lab/photometric-lab-hr-emission-1.png") as f:
            emission_img1 = Image.open(f).convert("RGBA")
        make_images(animation_img1, emission_img1, PHOTOMETRIC_LAB_RED_LIGHT_DST_1, PHOTOMETRIC_LAB_OVERLAY_DST_1, PHOTOMETRIC_LAB_MASK_DST_1, FRAMES_1)

        with open_file("graphics/entity/fusion-lab/photometric-lab-hr-animation-2.png") as f:
            animation_img2 = Image.open(f).convert("RGBA")
        with open_file("graphics/entity/fusion-lab/photometric-lab-hr-emission-2.png") as f:
            emission_img2 = Image.open(f).convert("RGBA")
        make_images(animation_img2, emission_img2, PHOTOMETRIC_LAB_RED_LIGHT_DST_2, PHOTOMETRIC_LAB_OVERLAY_DST_2, PHOTOMETRIC_LAB_MASK_DST_2, FRAMES_2)
