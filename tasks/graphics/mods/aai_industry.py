"""Generate overlay graphics for AAI Industry mod."""

import numpy as np
from PIL import Image

from lib import (
    GRAPHICS_DIR,
    LAB_LIGHT_PNG,
    LAB_LIGHT_FRAME_W,
    LAB_LIGHT_FRAME_H,
    LAB_LIGHT_FRAMES,
    LAB_LIGHT_COLS,
    save_image,
    extract_frame,
    assemble_grid,
)

AAI_DST_DIR = GRAPHICS_DIR / "factorio"
BURNER_LAB_OVERLAY_DST = AAI_DST_DIR / "aai-burner-lab-overlay.png"

# Burner-lab sprite frame dimensions
OVERLAY_FRAME_W, OVERLAY_FRAME_H = 194, 174
OVERLAY_OFFSET_X = (LAB_LIGHT_FRAME_W - OVERLAY_FRAME_W) // 2
OVERLAY_OFFSET_Y = (LAB_LIGHT_FRAME_H - OVERLAY_FRAME_H) // 2

# The chimney is a short cylinder placed at the top of the burner-lab.
# We mask out the cylinder of the chimney, leaving the hole and dome body colored.
CHIMNEY_CX = 98  # Chimney center X
CHIMNEY_W, CHIMNEY_H = 26, 18  # Chimney surface size
CHIMNEY_TOP_CY = 18  # Chimney top surface center Y
CHIMNEY_BOTTOM_CY = 34  # Chimney bottom surface center Y
HOLE_CY = 23  # Inner hole center
HOLE_W, HOLE_H = 16, 7  # Inner hole size

# Reference pixel for hole fill brightness
HOLE_REF_X = CHIMNEY_CX
HOLE_REF_Y = CHIMNEY_BOTTOM_CY + 20


def generate_aai_industry_images() -> None:
    lab_light = np.array(Image.open(LAB_LIGHT_PNG).convert("L")).astype(np.float32)

    # Chimney mask
    ys, xs = np.ogrid[:OVERLAY_FRAME_H, :OVERLAY_FRAME_W]
    cylinder_top = ((xs - CHIMNEY_CX) / CHIMNEY_W) ** 2 + ((ys - CHIMNEY_TOP_CY) / CHIMNEY_H) ** 2 <= 1.0
    cylinder_side = (((xs - CHIMNEY_CX) / CHIMNEY_W) ** 2 <= 1.0) & (ys >= CHIMNEY_TOP_CY) & (ys <= CHIMNEY_BOTTOM_CY)
    cylinder_bottom = ((xs - CHIMNEY_CX) / CHIMNEY_W) ** 2 + ((ys - CHIMNEY_BOTTOM_CY) / CHIMNEY_H) ** 2 <= 1.0
    cylinder = cylinder_top | cylinder_side | cylinder_bottom
    hole = ((xs - CHIMNEY_CX) / HOLE_W) ** 2 + ((ys - HOLE_CY) / HOLE_H) ** 2 <= 1.0
    chimney = cylinder & ~hole

    frames = []
    for i in range(LAB_LIGHT_FRAMES):
        frame = extract_frame(
            lab_light,
            i,
            LAB_LIGHT_FRAME_W,
            LAB_LIGHT_FRAME_H,
            LAB_LIGHT_COLS,
            offset_x=OVERLAY_OFFSET_X,
            offset_y=OVERLAY_OFFSET_Y,
            capture_w=OVERLAY_FRAME_W,
            capture_h=OVERLAY_FRAME_H,
        )

        # Brighten (same as vanilla lab overlay)
        frame = (frame * 1.5).clip(0, 255)

        # Mask out the chimney
        frame[chimney] = 0.0

        # Fill the hole with the brightness of the reference pixel
        hole_brightness = float(frame[HOLE_REF_Y, HOLE_REF_X])
        frame[hole] = hole_brightness

        frames.append(frame.astype(np.uint8))

    sheet = assemble_grid(frames, LAB_LIGHT_COLS)
    save_image(Image.fromarray(sheet, "L"), BURNER_LAB_OVERLAY_DST)
