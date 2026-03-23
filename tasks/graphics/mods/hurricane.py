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
FRAMES_1 = 64
FRAMES_2 = 16
COLS = 8
FRAME_W, FRAME_H = 330, 390

HURRICANE_DST_DIR = GRAPHICS_DIR / "hurricane"


def generate_hurricane_images():
    emission_frames: list[np.ndarray] = []
    for emission_src, overlay_dst, frame_count in [
        (HURRICANE_SRC_DIR / "photometric-lab-hr-emission1-1.png", HURRICANE_DST_DIR / "photometric-lab-hr-overlay-1.png", FRAMES_1),
        (HURRICANE_SRC_DIR / "photometric-lab-hr-emission1-2.png", HURRICANE_DST_DIR / "photometric-lab-hr-overlay-2.png", FRAMES_2),
    ]:
        emission_img = fill_black_background(Image.open(emission_src).convert("RGBA"))

        # Overlay: grayscale + brighten
        grayscale = np.array(emission_img.convert("L")).astype(np.float32)
        overlay = np.clip(grayscale * 1.5, 0, 255)  # Brighten
        save_image(Image.fromarray(overlay.astype(np.uint8), "L"), overlay_dst)

        # Extract all grayscaled frames
        for i in range(frame_count):
            emission_frames.append(extract_frame(grayscale, i, FRAME_W, FRAME_H, COLS))

    # Get mask from stacked grayscaled frames by max
    stack = np.stack(emission_frames, axis=0)
    mask = (stack.max(axis=0) > 0)[..., np.newaxis]

    # Remove garbage in the left-bottom
    mask[220:390, 0:148] = 0

    trasparent = np.zeros((FRAME_H, FRAME_W, 4), dtype=np.uint8)
    for animation_src, override_dst, frame_count in [
        (HURRICANE_SRC_DIR / "photometric-lab-hr-animation-1.png", HURRICANE_DST_DIR / "photometric-lab-hr-override-1.png", FRAMES_1),
        (HURRICANE_SRC_DIR / "photometric-lab-hr-animation-2.png", HURRICANE_DST_DIR / "photometric-lab-hr-override-2.png", FRAMES_2),
    ]:
        animation = np.array(Image.open(animation_src).convert("RGBA")).astype(np.uint8)

        frames = []
        for i in range(frame_count):
            frame = extract_frame(animation, i, FRAME_W, FRAME_H, COLS)
            frame = np.where(mask, frame, trasparent)  # Remove masked pixels
            frames.append(frame)

        grid = assemble_grid(frames, COLS)
        save_image(Image.fromarray(grid, "RGBA"), override_dst)
