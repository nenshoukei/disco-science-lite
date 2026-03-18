"""Generate overlay graphics for vanilla Factorio labs."""

import numpy as np
from PIL import Image, ImageFilter

from lib import FACTORIO_DATA, GRAPHICS_DIR, LAB_LIGHT_PNG, save_image

# --- Lab ---

LAB_OVERLAY_DST = GRAPHICS_DIR / "factorio/lab-overlay.png"


def generate_lab_images():
    light = np.array(Image.open(LAB_LIGHT_PNG).convert("L"))  # Grayscaled
    overlay = (light * 1.5).clip(0, 255)  # Brightening
    save_image(Image.fromarray(overlay.astype(np.uint8), "L"), LAB_OVERLAY_DST)


# --- Biolab ---

BIOLAB_LIGHT_SRC = FACTORIO_DATA / "space-age/graphics/entity/biolab/biolab-lights.png"

BIOLAB_OVERLAY_DST = GRAPHICS_DIR / "factorio/biolab-overlay.png"


def generate_biolab_images():
    light = np.array(Image.open(BIOLAB_LIGHT_SRC).convert("L")).astype(np.float32)  # Grayscaled
    light = np.clip(light * 4.0, 0, 255)  # Strong brightening

    # Additive-blend a blurred version for glow effect — apply blur once on the full sheet.
    light_blurred = np.array(Image.fromarray(light.astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(radius=12))).astype(np.float32)
    light = np.clip(light + light_blurred * 1.5, 0, 255)

    save_image(Image.fromarray(light.astype(np.uint8), "L"), BIOLAB_OVERLAY_DST)


# --- General overlay ---

GENERAL_SIZE = 128
GENERAL_RADIUS = GENERAL_SIZE / 2
GENERAL_FALLOFF = 0.8  # exponent applied to gradient: <1 = more white in center with steep edge

GENERAL_OVERLAY_DST = GRAPHICS_DIR / "general-overlay.png"


def generate_general_overlay():
    # Draw a gradient circle.
    cx, cy = GENERAL_SIZE / 2.0, GENERAL_SIZE / 2.0
    ys, xs = np.ogrid[:GENERAL_SIZE, :GENERAL_SIZE]
    dist = np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2)
    gradient = np.clip(1.0 - np.divide(dist, GENERAL_RADIUS), 0.0, 1.0) ** GENERAL_FALLOFF
    save_image(Image.fromarray((gradient * 255.0).round().astype(np.uint8), "L"), GENERAL_OVERLAY_DST)
