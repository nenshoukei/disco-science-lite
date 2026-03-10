"""Generate overlay graphics for disco-science-lite mod."""

import math
from pathlib import Path

import numpy as np
from PIL import Image

# https://wiki.factorio.com/Application_directory#Application_directory
_FACTORIO_CANDIDATES = [
    # Windows
    Path("C:/Program Files (x86)/Steam/steamapps/common/Factorio"),
    Path("C:/Program Files/Factorio"),
    # macOS
    Path.home() / "Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents",
    Path("/Applications/factorio.app/Contents"),
    # Linux
    Path.home() / ".steam/steam/steamapps/common/Factorio",
    Path.home() / ".factorio",
]

def _find_factorio_data() -> Path:
    for candidate in _FACTORIO_CANDIDATES:
        data = candidate / "data"
        if data.is_dir():
            return data
    paths = "\n  ".join(str(p / "data") for p in _FACTORIO_CANDIDATES)
    raise FileNotFoundError(f"Factorio data directory not found. Searched:\n  {paths}")

FACTORIO_DATA = _find_factorio_data()

ROOT_DIR = Path(__file__).parent.parent
GRAPHICS_DIR = ROOT_DIR / "graphics"

# Lab overlay: 33 frames (216x194 each, 11 columns x 3 rows), animation_speed = 1/3
LAB_SRC = FACTORIO_DATA / "base/graphics/entity/lab/lab-light.png"
LAB_FRAME_W, LAB_FRAME_H = 216, 194
LAB_COLS, LAB_FRAMES = 11, 33

# Biolab overlay: 32 frames (326x362 each, 8 columns x 4 rows), animation_speed = 1/3
BIOLAB_SRC = FACTORIO_DATA / "space-age/graphics/entity/biolab/biolab-lights.png"
BIOLAB_FRAME_W, BIOLAB_FRAME_H = 326, 362
BIOLAB_COLS, BIOLAB_FRAMES = 8, 32

def apply_level(arr: np.ndarray, white_point: float = 0.8, gamma: float = 1.5) -> np.ndarray:
    """Apply ImageMagick-style -level "0,white_point*100%,gamma" to a uint8 grayscale array.

    Replicates: convert input -level "0,{white_point*100}%,{gamma}" output
    """
    f = arr.astype(np.float32) / 255.0
    f = np.clip(f / white_point, 0.0, 1.0)
    f = np.power(f, 1.0 / gamma)
    return (f * 255.0).round().astype(np.uint8)

def extract_frame(arr: np.ndarray, idx: int, frame_w: int, frame_h: int, cols: int) -> np.ndarray:
    col, row = idx % cols, idx // cols
    return arr[row * frame_h:(row + 1) * frame_h, col * frame_w:(col + 1) * frame_w]

def assemble_grid(frames: list[np.ndarray], cols: int) -> Image.Image:
    rows = math.ceil(len(frames) / cols)
    fh, fw = frames[0].shape
    sheet = np.zeros((rows * fh, cols * fw), dtype=np.uint8)
    for i, frame in enumerate(frames):
        col, row = i % cols, i // cols
        sheet[row * fh:(row + 1) * fh, col * fw:(col + 1) * fw] = frame
    return Image.fromarray(sheet, "L")

# --- Lab overlay ---
# Convert to grayscale and apply level adjustment. The natural brightness variation
# across frames (bright vs. dark frames) produces the flicker effect in-game.

lab_src = np.array(Image.open(LAB_SRC).convert("L"))
lab_frames = []
lab_frame_brightness = []

for i in range(LAB_FRAMES):
    frame = extract_frame(lab_src, i, LAB_FRAME_W, LAB_FRAME_H, LAB_COLS)
    lab_frame_brightness.append(float(frame.mean()))
    lab_frames.append(apply_level(frame, white_point=0.8, gamma=1.5))

assemble_grid(lab_frames, LAB_COLS).save(GRAPHICS_DIR / "lab-overlay.png")
print("Generated lab-overlay.png")

# --- Biolab overlay ---
# Resample lab's flicker pattern (33 frames) to 32 frames and apply it as a
# per-frame brightness multiplier. This gives biolab the same flicker character
# as lab. Combined with matching animation_speed (1/3), the blink period is
# 32 / (1/3) = 96 ticks ≈ lab's 33 / (1/3) = 99 ticks.

max_b = max(lab_frame_brightness)
lab_brightness_norm = [b / max_b for b in lab_frame_brightness]

biolab_src = np.array(Image.open(BIOLAB_SRC).convert("L"))
biolab_frames = []

for i in range(BIOLAB_FRAMES):
    # Linear interpolation of lab brightness pattern resampled to BIOLAB_FRAMES
    t = i / BIOLAB_FRAMES  # 0.0 to (BIOLAB_FRAMES-1)/BIOLAB_FRAMES
    pos = t * LAB_FRAMES
    i0 = int(pos) % LAB_FRAMES
    i1 = (i0 + 1) % LAB_FRAMES
    frac = pos - int(pos)
    brightness = lab_brightness_norm[i0] * (1.0 - frac) + lab_brightness_norm[i1] * frac

    frame = extract_frame(biolab_src, i, BIOLAB_FRAME_W, BIOLAB_FRAME_H, BIOLAB_COLS)
    leveled = apply_level(frame, white_point=0.8, gamma=6.0).astype(np.float32)
    result = np.clip(leveled * brightness, 0, 255).round().astype(np.uint8)
    biolab_frames.append(result)

assemble_grid(biolab_frames, BIOLAB_COLS).save(GRAPHICS_DIR / "biolab-overlay.png")
print("Generated biolab-overlay.png")

# --- General overlay ---
# 33 frames of radial gradients (white center → black edge) using lab's flicker
# pattern as multipliers. animation_speed = 1/3 → 33 / (1/3) = 99 ticks/cycle,
# exactly matching lab-overlay.

GENERAL_SIZE = 128
GENERAL_RADIUS = GENERAL_SIZE / 2  # gradient reaches 0 at this distance from center
GENERAL_FALLOFF = 0.8  # exponent applied to gradient: <1 = more white in center with steep edge

cx, cy = GENERAL_SIZE / 2.0, GENERAL_SIZE / 2.0
ys, xs = np.ogrid[:GENERAL_SIZE, :GENERAL_SIZE]
dist = np.sqrt((xs - cx)**2 + (ys - cy)**2)
base_gradient = np.clip(1.0 - dist / GENERAL_RADIUS, 0.0, 1.0) ** GENERAL_FALLOFF

general_frames = []
for m in lab_brightness_norm:
    frame = np.clip(base_gradient * m, 0.0, 1.0)
    general_frames.append((frame * 255.0).round().astype(np.uint8))

assemble_grid(general_frames, LAB_COLS).save(GRAPHICS_DIR / "general-overlay.png")
print("Generated general-overlay.png")
