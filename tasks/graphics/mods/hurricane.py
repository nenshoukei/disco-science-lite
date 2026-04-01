"""Generate overlay graphics for Hurricane lab sprites from Fusion lab mod."""

import numpy as np
from PIL import Image

from lib import (
    SOURCE_DIR,
    GRAPHICS_DIR,
    fill_black_background,
    extract_frame,
    assemble_grid,
    save_image,
)

HURRICANE_SRC_DIR = SOURCE_DIR / "hurricane"
PL_FRAMES_1 = 64
PL_FRAMES_2 = 16
PL_COLS = 8
PL_FRAME_W, PL_FRAME_H = 330, 390

FR_FRAMES = 60
FR_COLS = 8
FR_FRAME_W, FR_FRAME_H = 400, 400


HURRICANE_DST_DIR = GRAPHICS_DIR / "hurricane"


def generate_hurricane_arc_furnace_images():
    emission_img = Image.open(HURRICANE_SRC_DIR / "arc-furnace-hr-emission-1.png").convert("RGBA")
    emission_img = fill_black_background(emission_img)

    # Overlay: grayscale + brighten
    grayscale = np.array(emission_img.convert("L")).astype(np.float32)
    overlay = np.clip(grayscale * 1.2, 0, 255)  # Brighten
    save_image(Image.fromarray(overlay.astype(np.uint8), "L"), HURRICANE_DST_DIR / "arc-furnace-hr-overlay.png")


def generate_hurricane_fusion_reactor_images():
    emission_img = Image.open(HURRICANE_SRC_DIR / "fusion-reactor-hr-emission-1.png").convert("RGBA")
    emission_img = fill_black_background(emission_img)

    # Overlay: grayscale + brighten
    grayscale = np.array(emission_img.convert("L")).astype(np.float32)
    overlay = np.clip(grayscale * 1.5, 0, 255)  # Brighten
    save_image(Image.fromarray(overlay.astype(np.uint8), "L"), HURRICANE_DST_DIR / "fusion-reactor-hr-overlay.png")


def generate_hurricane_research_center_images():
    emission_img1 = Image.open(HURRICANE_SRC_DIR / "research-center-emission1.png").convert("L")
    emission_img2 = Image.open(HURRICANE_SRC_DIR / "research-center-emission2.png").convert("L")

    # Overlay: grayscale + additive blend
    overlay = np.array(emission_img1).astype(np.float32) + np.array(emission_img2).astype(np.float32)
    overlay = np.clip(overlay, 0, 255)
    save_image(Image.fromarray(overlay.astype(np.uint8), "L"), HURRICANE_DST_DIR / "research-center-overlay.png")


def generate_hurricane_photometric_lab_images():
    emission_frames: list[np.ndarray] = []
    for emission_src, overlay_dst, frame_count in [
        (HURRICANE_SRC_DIR / "photometric-lab-hr-emission1-1.png", HURRICANE_DST_DIR / "photometric-lab-hr-overlay-1.png", PL_FRAMES_1),
        (HURRICANE_SRC_DIR / "photometric-lab-hr-emission1-2.png", HURRICANE_DST_DIR / "photometric-lab-hr-overlay-2.png", PL_FRAMES_2),
    ]:
        emission_img = fill_black_background(Image.open(emission_src).convert("RGBA"))

        # Overlay: grayscale + brighten
        grayscale = np.array(emission_img.convert("L")).astype(np.float32)
        overlay = np.clip(grayscale * 1.5, 0, 255)  # Brighten
        save_image(Image.fromarray(overlay.astype(np.uint8), "L"), overlay_dst)

        # Extract all grayscaled frames
        for i in range(frame_count):
            emission_frames.append(extract_frame(grayscale, i, PL_FRAME_W, PL_FRAME_H, PL_COLS))

    # Get mask from stacked grayscaled frames by max
    stack = np.stack(emission_frames, axis=0)
    mask = (stack.max(axis=0) > 0)[..., np.newaxis]

    # Remove garbage in the left-bottom
    mask[220:390, 0:148] = 0

    trasparent = np.zeros((PL_FRAME_H, PL_FRAME_W, 4), dtype=np.uint8)
    for animation_src, override_dst, frame_count in [
        (HURRICANE_SRC_DIR / "photometric-lab-hr-animation-1.png", HURRICANE_DST_DIR / "photometric-lab-hr-override-1.png", PL_FRAMES_1),
        (HURRICANE_SRC_DIR / "photometric-lab-hr-animation-2.png", HURRICANE_DST_DIR / "photometric-lab-hr-override-2.png", PL_FRAMES_2),
    ]:
        animation = np.array(Image.open(animation_src).convert("RGBA")).astype(np.uint8)

        frames = []
        for i in range(frame_count):
            frame = extract_frame(animation, i, PL_FRAME_W, PL_FRAME_H, PL_COLS)
            frame = np.where(mask, frame, trasparent)  # Remove masked pixels
            frames.append(frame)

        grid = assemble_grid(frames, PL_COLS)
        save_image(Image.fromarray(grid, "RGBA"), override_dst)
