"""Generate overlay graphics for disco-science-lite mod."""

import glob as _glob
import math
import zipfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
import oxipng

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

# Lab overlay: 33 frames (216x194 each, 11 columns x 3 rows), animation_speed = 1/3
LAB_SRC = FACTORIO_DATA / "base/graphics/entity/lab/lab-light.png"
LAB_FRAME_W, LAB_FRAME_H = 216, 194
LAB_COLS, LAB_FRAMES = 11, 33

LAB_OVERLAY_DST = GRAPHICS_DIR / "factorio/lab-overlay.png"

def generate_lab_overlay():
    global lab_brightness_norm

    lab_src = np.array(Image.open(LAB_SRC).convert("L"))
    overlay_frames = []
    lab_frame_brightness = []

    for i in range(LAB_FRAMES):
        frame = extract_frame(lab_src, i, LAB_FRAME_W, LAB_FRAME_H, LAB_COLS)
        lab_frame_brightness.append(float(frame.mean()))
        overlay_frames.append(apply_level(frame, white_point=0.8, gamma=1.5))

    max_b = max(lab_frame_brightness)
    lab_brightness_norm = [b / max_b for b in lab_frame_brightness]

    assemble_grid(overlay_frames, LAB_COLS).save(LAB_OVERLAY_DST)
    oxipng.optimize(LAB_OVERLAY_DST)
    print("Generated", LAB_OVERLAY_DST)

generate_lab_overlay()

# --- Biolab overlay ---
# Resample lab's flicker pattern (33 frames) to 32 frames and apply it as a
# per-frame brightness multiplier. This gives biolab the same flicker character
# as lab. Combined with matching animation_speed (1/3), the blink period is
# 32 / (1/3) = 96 ticks ≈ lab's 33 / (1/3) = 99 ticks.

# Biolab overlay: 32 frames (326x362 each, 8 columns x 4 rows), animation_speed = 1/3
BIOLAB_SRC = FACTORIO_DATA / "space-age/graphics/entity/biolab/biolab-lights.png"
BIOLAB_FRAME_W, BIOLAB_FRAME_H = 326, 362
BIOLAB_COLS, BIOLAB_FRAMES = 8, 32

BIOLAB_OVERLAY_DST = GRAPHICS_DIR / "factorio/biolab-overlay.png"

def generate_biolab_overlay():
    biolab_src = np.array(Image.open(BIOLAB_SRC).convert("L"))
    overlay_frames = []

    # Vertical fade mask: suppress stray artifact pixels near the top of each frame.
    # Artifacts (stray lights from biolab animation) appear at y≈22-40; the main body
    # starts around y=50. Hold 0 until y=BIOLAB_MASK_START, then ramp to 1 at y=BIOLAB_MASK_END.
    # Applied before glow so artifacts don't contribute to blur spread either.
    BIOLAB_MASK_START = 50
    BIOLAB_MASK_END = 70
    top_mask = np.ones(BIOLAB_FRAME_H, dtype=np.float32)
    top_mask[:BIOLAB_MASK_START] = 0.0
    top_mask[BIOLAB_MASK_START:BIOLAB_MASK_END] = np.linspace(0.0, 1.0, BIOLAB_MASK_END - BIOLAB_MASK_START)
    top_mask = top_mask[:, np.newaxis]  # column vector for broadcasting

    for i in range(BIOLAB_FRAMES):
        # Linear interpolation of lab brightness pattern resampled to BIOLAB_FRAMES
        t = i / BIOLAB_FRAMES  # 0.0 to (BIOLAB_FRAMES-1)/BIOLAB_FRAMES
        pos = t * LAB_FRAMES
        i0 = int(pos) % LAB_FRAMES
        i1 = (i0 + 1) % LAB_FRAMES
        frac = pos - int(pos)
        brightness = (lab_brightness_norm[i0] * (1.0 - frac) + lab_brightness_norm[i1] * frac) * 2

        frame = extract_frame(biolab_src, i, BIOLAB_FRAME_W, BIOLAB_FRAME_H, BIOLAB_COLS)
        leveled = apply_level(frame, white_point=0.8, gamma=2.0).astype(np.float32) * top_mask
        brightened = np.clip(leveled * brightness, 0, 255)
        # Glow: blur and screen-blend onto the brightened frame
        glow = np.array(
            Image.fromarray(brightened.astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(radius=15))
        ).astype(np.float32)
        result = np.clip(255.0 - (255.0 - brightened) * (255.0 - glow) / 255.0, 0, 255).round().astype(np.uint8)
        overlay_frames.append(result)

    assemble_grid(overlay_frames, BIOLAB_COLS).save(BIOLAB_OVERLAY_DST)
    oxipng.optimize(BIOLAB_OVERLAY_DST)
    print("Generated", BIOLAB_OVERLAY_DST)

generate_biolab_overlay()

# --- General overlay ---
# 33 frames of radial gradients (white center → black edge) using lab's flicker
# pattern as multipliers. animation_speed = 1/3 → 33 / (1/3) = 99 ticks/cycle,
# exactly matching lab-overlay.

GENERAL_SIZE = 128
GENERAL_RADIUS = GENERAL_SIZE / 2  # gradient reaches 0 at this distance from center
GENERAL_FALLOFF = 0.8  # exponent applied to gradient: <1 = more white in center with steep edge

GENERAL_OVERLAY_DST = GRAPHICS_DIR / "general-overlay.png"

def generate_general_overlay():
    cx, cy = GENERAL_SIZE / 2.0, GENERAL_SIZE / 2.0
    ys, xs = np.ogrid[:GENERAL_SIZE, :GENERAL_SIZE]
    dist = np.sqrt((xs - cx)**2 + (ys - cy)**2)
    base_gradient = np.clip(1.0 - dist / GENERAL_RADIUS, 0.0, 1.0) ** GENERAL_FALLOFF

    overlay_frames = []
    for m in lab_brightness_norm:
        frame = np.clip(base_gradient * m, 0.0, 1.0)
        overlay_frames.append((frame * 255.0).round().astype(np.uint8))

    assemble_grid(overlay_frames, LAB_COLS).save(GENERAL_OVERLAY_DST)
    oxipng.optimize(GENERAL_OVERLAY_DST)
    print("Generated", GENERAL_OVERLAY_DST)

generate_general_overlay()

# --- LabOMatic lab albedo (modified + overlay) ---
# Source: LabOMatic_*.zip/LabOMatic/graphics/lab_albedo_anim.png
# The dome has a blue cast; neutralise it so additive color overlays render cleanly.

_labomatic_zips = sorted(_glob.glob(str(ROOT_DIR.parent / "LabOMatic_*.zip")))
if not _labomatic_zips:
    raise FileNotFoundError(f"LabOMatic_*.zip not found in {ROOT_DIR.parent}")
LABOMATIC_ZIP = Path(_labomatic_zips[-1])

LABORAT_DIR = GRAPHICS_DIR / "laborat"
LABORAT_MODIFIED_DST = LABORAT_DIR / "lab_albedo_anim-modified.png"
LABORAT_OVERLAY_DST  = LABORAT_DIR / "lab_albedo_anim-overlay.png"

LABORAT_FRAME_W, LABORAT_FRAME_H = 150, 150
LABORAT_FRAMES, LABORAT_COLS = 30, 10

def generate_laborat_overlay():
    with zipfile.ZipFile(LABOMATIC_ZIP) as z:
        with z.open("LabOMatic/graphics/lab_albedo_anim.png") as f:
            img = Image.open(f)
            img.load()
        img = img.convert("RGBA")
        with z.open("LabOMatic/graphics/lab_light_anim.png") as f:
            light_img = Image.open(f)
            light_img.load()
        light_img = light_img.convert("RGBA")

    # Step 1: Grayscale + brightness reduction → modified image (keeps original 30-frame layout).
    la = img.convert("LA")
    l, a = la.getchannel("L"), la.getchannel("A")
    l_dark = np.clip(np.array(l).astype(np.float32) * 0.6, 0, 255).round().astype(np.uint8)
    l_dark_img = Image.fromarray(l_dark, "L")
    modified_img = Image.merge("RGBA", (l_dark_img, l_dark_img, l_dark_img, a))
    modified_img.save(LABORAT_MODIFIED_DST)
    oxipng.optimize(LABORAT_MODIFIED_DST)
    print("Generated", LABORAT_MODIFIED_DST)

    # Step 2: Overlay with lab-like flicker — 30 frames, lab_brightness_norm resampled to 30.
    # Exact sync with lab is not needed (animation_offset is random), but the flicker
    # character (period, depth) will match.
    laborat_brightness = []
    for i in range(LABORAT_FRAMES):
        t = i / LABORAT_FRAMES * LAB_FRAMES
        i0 = int(t) % LAB_FRAMES
        i1 = (i0 + 1) % LAB_FRAMES
        frac = t - int(t)
        laborat_brightness.append(lab_brightness_norm[i0] * (1 - frac) + lab_brightness_norm[i1] * frac)

    gray_src = np.array(img.convert("L"))
    light_src = np.array(light_img.convert("L"))
    overlay_frames = []
    for i in range(LABORAT_FRAMES):
        frame = extract_frame(gray_src, i, LABORAT_FRAME_W, LABORAT_FRAME_H, LABORAT_COLS)
        leveled = apply_level(frame, white_point=1.0, gamma=1.0).astype(np.float32)
        brightened = np.clip(leveled * laborat_brightness[i], 0, 255)

        light_frame = extract_frame(light_src, i, LABORAT_FRAME_W, LABORAT_FRAME_H, LABORAT_COLS)
        light_darkened = light_frame.astype(np.float32) * 0.8

        result = np.clip(brightened + light_darkened, 0, 255).round().astype(np.uint8)
        overlay_frames.append(result)

    assemble_grid(overlay_frames, LABORAT_COLS).save(LABORAT_OVERLAY_DST)
    oxipng.optimize(LABORAT_OVERLAY_DST)
    print("Generated", LABORAT_OVERLAY_DST)

generate_laborat_overlay()
