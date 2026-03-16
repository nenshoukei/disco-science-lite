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

def fill_black_background(img: Image.Image) -> Image.Image:
    """Paste onto black background to ensure transparent areas are black (0, 0, 0)"""
    bg = Image.new("RGBA", img.size, (0, 0, 0, 0))
    bg.paste(img, mask=img)
    return bg

def rgb_to_grayscale(r: np.ndarray, g: np.ndarray, b: np.ndarray) -> np.ndarray:
    """Convert r, g, b arrays into a grayscale array"""
    # Weighted average same as Pillow's convert L
    return (0.299 * r + 0.587 * g + 0.114 * b).clip(0, 255)

def extract_frame(arr: np.ndarray, idx: int, frame_w: int, frame_h: int, cols: int) -> np.ndarray:
    """Extract a frame from a grid image"""
    col, row = idx % cols, idx // cols
    return arr[row * frame_h:(row + 1) * frame_h, col * frame_w:(col + 1) * frame_w]

def assemble_grid(frames: list[np.ndarray], cols: int) -> np.ndarray:
    """Assemble frames into a grid image"""
    frame_h, frame_w = frames[0].shape[:2]
    rows = math.ceil(len(frames) / cols)
    # Support both 2D (L) and 3D (LA, RGB, RGBA) frames
    sheet_shape = (rows * frame_h, cols * frame_w) + frames[0].shape[2:]
    sheet = np.zeros(sheet_shape, dtype=np.uint8)
    for i, frame in enumerate(frames):
        col, row = i % cols, i // cols
        sheet[row * frame_h:(row + 1) * frame_h, col * frame_w:(col + 1) * frame_w] = frame
    return sheet

def resize_mask(mask: np.ndarray, width: int, height: int, img_shift: tuple[float, float] = (0, 0), mask_shift: tuple[float, float] = (0, 0)) -> np.ndarray:
    """Resize a mask image to (width, height), respecting shift values."""
    mh, mw = mask.shape[:2]

    # Both images are placed on a virtual canvas with their centers at their respective shifts.
    # For pixel (py, px), the corresponding mask pixel is (py + dy, px + dx).
    dx = round((img_shift[0] - mask_shift[0]) + (mw - width) / 2)
    dy = round((img_shift[1] - mask_shift[1]) + (mh - height) / 2)

    # Build sized_mask as given size, filled from mask where overlap exists, 0 elsewhere.
    sized_mask = np.zeros((height, width), dtype=np.float32)
    ix0 = max(0, -dx)
    iy0 = max(0, -dy)
    ix1 = min(width, mw - dx)
    iy1 = min(height, mh - dy)
    sized_mask[iy0:iy1, ix0:ix1] = mask[iy0 + dy : iy1 + dy, ix0 + dx : ix1 + dx]

    return sized_mask

def grayscale_image_by_binary_mask(img: np.ndarray, mask: np.ndarray, brightness: float = 1.0) -> np.ndarray:
    """Generate an image with binary mask. Where mask is true, grayscaled. Where mask is false, keep original."""
    r = img[:, :, 0].astype(np.float32)
    g = img[:, :, 1].astype(np.float32)
    b = img[:, :, 2].astype(np.float32)

    gray = (rgb_to_grayscale(r, g, b).astype(np.float32) * brightness)

    result = img.copy()
    result[:, :, 0] = np.where(mask, gray, r)
    result[:, :, 1] = np.where(mask, gray, g)
    result[:, :, 2] = np.where(mask, gray, b)
    return result

def grayscale_image_by_saturation_mask(img: np.ndarray, mask: np.ndarray) -> np.ndarray:
    """Generate an image with Saturation mask. Where mask is 255, S becomes 0. Where mask is 0, S keeps original. """
    sat_scale = 1.0 - np.clip(mask, 0, 255) / 255.0
    r = img[:, :, 0].astype(np.float32) / 255.0
    g = img[:, :, 1].astype(np.float32) / 255.0
    b = img[:, :, 2].astype(np.float32) / 255.0
    v = np.maximum(np.maximum(r, g), b)

    # To change S in RGB: channel' = V + (channel - V) * scale, where V = max(R,G,B)
    result = img.copy()
    result[:, :, 0] = np.clip((v + (r - v) * sat_scale) * 255, 0, 255).astype(img.dtype)
    result[:, :, 1] = np.clip((v + (g - v) * sat_scale) * 255, 0, 255).astype(img.dtype)
    result[:, :, 2] = np.clip((v + (b - v) * sat_scale) * 255, 0, 255).astype(img.dtype)
    return result

def save_image(img: Image.Image, dst_path: Path) -> None:
    img.save(dst_path)
    oxipng.optimize(dst_path)
    print("Generated", dst_path)

# --- Lab ---

LAB_ANIM_SRC = FACTORIO_DATA / "base/graphics/entity/lab/lab.png"
LAB_ANIM_FRAME_W, LAB_ANIM_FRAME_H = 194, 174
LAB_ANIM_FRAME_SHIFT = (0, 1.5)
LAB_LIGHT_SRC = FACTORIO_DATA / "base/graphics/entity/lab/lab-light.png"
LAB_LIGHT_FRAME_W, LAB_LIGHT_FRAME_H = 216, 194
LAB_LIGHT_FRAME_SHIFT = (0, 0)
LAB_COLS = 11
LAB_FRAMES = 33

LAB_MASKED_DST = GRAPHICS_DIR / "factorio/lab-masked.png"
LAB_OVERLAY_DST = GRAPHICS_DIR / "factorio/lab-overlay.png"

lab_frame_brightness: list[float]

def generate_lab_images():
    global lab_frame_brightness

    anim = np.array(Image.open(LAB_ANIM_SRC).convert("RGBA"))
    light = np.array(Image.open(LAB_LIGHT_SRC).convert("L")) # Grayscaled

    # Overlay: Brightening.
    overlay = (light * 1.5).clip(0, 255)
    save_image(Image.fromarray(overlay.astype(np.uint8), "L"), LAB_OVERLAY_DST)

    # Masked: Lab animation with grayscaled pixels for the overlay.
    masked_frames: list[np.ndarray] = []
    frame_brightness: list[float] = []
    for i in range(LAB_FRAMES):
        # Extract frame from grid image.
        anim_frame = extract_frame(anim, i, LAB_ANIM_FRAME_W, LAB_ANIM_FRAME_H, LAB_COLS)
        light_frame = extract_frame(light, i, LAB_LIGHT_FRAME_W, LAB_LIGHT_FRAME_H, LAB_COLS)
        # Append a new frame with masked grayscaling.
        mask = resize_mask(light_frame, LAB_ANIM_FRAME_W, LAB_ANIM_FRAME_H, LAB_ANIM_FRAME_SHIFT, LAB_LIGHT_FRAME_SHIFT)
        masked_frames.append(grayscale_image_by_binary_mask(anim_frame, mask > 10, brightness=0.5))
        # Get light frame brightness to be used by other overlays.
        frame_brightness.append(float(light_frame.mean()))

    masked_assembled = assemble_grid(masked_frames, LAB_COLS)
    save_image(Image.fromarray(masked_assembled, "RGBA"), LAB_MASKED_DST)

    max_b = max(frame_brightness)
    lab_frame_brightness = [b / max_b for b in frame_brightness]


generate_lab_images()

# --- Biolab ---

BIOLAB_ANIM_SRC = FACTORIO_DATA / "space-age/graphics/entity/biolab/biolab-anim.png"
BIOLAB_ANIM_FRAME_W, BIOLAB_ANIM_FRAME_H = 366, 404
BIOLAB_ANIM_FRAME_SHIFT = (2.0, -5.0)
BIOLAB_LIGHT_SRC = FACTORIO_DATA / "space-age/graphics/entity/biolab/biolab-lights.png"
BIOLAB_LIGHT_FRAME_W, BIOLAB_LIGHT_FRAME_H = 326, 362
BIOLAB_LIGHT_FRAME_SHIFT = (1.0, -6.5)
BIOLAB_COLS = 8
BIOLAB_FRAMES = 32

BIOLAB_MASKED_DST = GRAPHICS_DIR / "factorio/biolab-masked.png"
BIOLAB_OVERLAY_DST = GRAPHICS_DIR / "factorio/biolab-overlay.png"

def generate_biolab_images():
    anim = np.array(Image.open(BIOLAB_ANIM_SRC).convert("RGBA")).astype(np.float32)
    light = np.array(Image.open(BIOLAB_LIGHT_SRC).convert("L")).astype(np.float32) # Grayscaled
    light = np.clip(light * 6.0, 0, 255) # Strong brightening

    overlay_frames = []
    masked_frames = []
    for i in range(BIOLAB_FRAMES):
        anim_frame = extract_frame(anim, i, BIOLAB_ANIM_FRAME_W, BIOLAB_ANIM_FRAME_H, BIOLAB_COLS)
        light_frame = extract_frame(light, i, BIOLAB_LIGHT_FRAME_W, BIOLAB_LIGHT_FRAME_H, BIOLAB_COLS)

        # Additive-blend the blurred frame for glow effect.
        blurred = np.array(Image.fromarray(light_frame.astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(radius=12))).astype(np.float32)
        light_frame = np.clip(light_frame + blurred * 1.5, 0, 255)
        overlay_frames.append(light_frame)

        sized_mask = resize_mask(light_frame, BIOLAB_ANIM_FRAME_W, BIOLAB_ANIM_FRAME_H, BIOLAB_ANIM_FRAME_SHIFT, BIOLAB_LIGHT_FRAME_SHIFT)
        masked_frames.append(grayscale_image_by_saturation_mask(anim_frame, sized_mask))

    overlay_assembled = assemble_grid(overlay_frames, BIOLAB_COLS)
    save_image(Image.fromarray(overlay_assembled.astype(np.uint8), "L"), BIOLAB_OVERLAY_DST)

    masked_assembled = assemble_grid(masked_frames, BIOLAB_COLS)
    save_image(Image.fromarray(masked_assembled.astype(np.uint8), "RGBA"), BIOLAB_MASKED_DST)

generate_biolab_images()

# --- General overlay ---

GENERAL_SIZE = 128
GENERAL_RADIUS = GENERAL_SIZE / 2
GENERAL_FALLOFF = 0.8  # exponent applied to gradient: <1 = more white in center with steep edge

GENERAL_OVERLAY_DST = GRAPHICS_DIR / "general-overlay.png"

def generate_general_overlay():
    # Draw a gradient circle.
    cx, cy = GENERAL_SIZE / 2.0, GENERAL_SIZE / 2.0
    ys, xs = np.ogrid[:GENERAL_SIZE, :GENERAL_SIZE]
    dist = np.sqrt((xs - cx)**2 + (ys - cy)**2)
    base_gradient = np.clip(1.0 - np.divide(dist, GENERAL_RADIUS), 0.0, 1.0) ** GENERAL_FALLOFF

    # Generate each frame with the same brightness as the lab overlay frames.
    overlay_frames = []
    for b in lab_frame_brightness:
        frame = np.clip(base_gradient * b, 0.0, 1.0)
        overlay_frames.append((frame * 255.0).round())

    assembled = assemble_grid(overlay_frames, LAB_COLS)
    save_image(Image.fromarray(assembled.astype(np.uint8), "L"), GENERAL_OVERLAY_DST)

generate_general_overlay()

# --- LabOMatic (laborat) ---

LABORAT_SRC = ROOT_DIR.parent / "LabOMatic_*.zip"
LABORAT_FRAME_W, LABORAT_FRAME_H = 150, 150
LABORAT_X4_FRAME_W, LABORAT_X4_FRAME_H = 600, 600
LABORAT_FRAMES = 30
LABORAT_COLS = 10

LABORAT_DST_DIR = GRAPHICS_DIR / "laborat"
LABORAT_MASKED_DST      = LABORAT_DST_DIR / "lab_albedo_anim-masked.png"
LABORAT_OVERLAY_DST     = LABORAT_DST_DIR / "lab_albedo_anim-overlay.png"
LABORAT_X4_MASKED_DST   = LABORAT_DST_DIR / "lab_albedo_anim_x4-masked.png"
LABORAT_X4_OVERLAY_DST  = LABORAT_DST_DIR / "lab_albedo_anim_x4-overlay.png"

def generate_laborat_overlay():
    # Find ../LabOMatic_*.zip
    _labomatic_zips = sorted(_glob.glob(str(LABORAT_SRC)))
    if not _labomatic_zips:
        raise FileNotFoundError(f"LabOMatic not found at: {LABORAT_SRC}")
    zip_path = Path(_labomatic_zips[-1])

    def make_images(anim_img: Image.Image, light_img: Image.Image, frame_w: int, frame_h: int, modified_dst: Path, overlay_dst: Path) -> None:
        anim_img = fill_black_background(anim_img)
        light_img = fill_black_background(light_img).convert("L")

        anim = np.array(anim_img).astype(np.float32)
        light = np.array(light_img).astype(np.float32)

        # Blue tinted pixels => grayscale, other pixels => black
        r, g, b = anim[..., 0], anim[..., 1], anim[..., 2]
        blue_mask = b > 60
        overlay_grid = np.where(blue_mask, rgb_to_grayscale(r, g, b), 0)

        # Blend light in additive mode
        overlay_grid = np.clip(overlay_grid + light, 0, 255)

        # Static overlay: max brightness across all frames, independent of entity animation.
        # Overlay animation cannot be synchronized with entity animation (rendering.draw_animation
        # starts from the current tick offset, not frame 0), so we use a single static frame.
        static_overlay = np.zeros((frame_h, frame_w), dtype=np.float32)
        for i in range(LABORAT_FRAMES):
            frame_overlay = extract_frame(overlay_grid, i, frame_w, frame_h, LABORAT_COLS)
            static_overlay = np.maximum(static_overlay, frame_overlay)

        # Darken
        static_overlay = np.clip(static_overlay * 0.8, 0, 255)
        save_image(Image.fromarray(static_overlay.astype(np.uint8), "L"), overlay_dst)

        masked = grayscale_image_by_binary_mask(anim, overlay_grid > 10, brightness=0.5)
        save_image(Image.fromarray(masked.astype(np.uint8), "RGBA"), modified_dst)

    with zipfile.ZipFile(zip_path) as z:
        with z.open("LabOMatic/graphics/lab_albedo_anim.png") as f:
            anim_img = Image.open(f).convert("RGBA")
        with z.open("LabOMatic/graphics/lab_light_anim.png") as f:
            light_img = Image.open(f).convert("RGBA")
        make_images(anim_img, light_img, LABORAT_FRAME_W, LABORAT_FRAME_H, LABORAT_MASKED_DST, LABORAT_OVERLAY_DST)

        with z.open("LabOMatic/graphics/lab_albedo_anim_x4.png") as f:
            anim_img_x4 = Image.open(f).convert("RGBA")
        with z.open("LabOMatic/graphics/lab_light_anim_x4.png") as f:
            light_img_x4 = Image.open(f).convert("RGBA")
        make_images(anim_img_x4, light_img_x4, LABORAT_X4_FRAME_W, LABORAT_X4_FRAME_H, LABORAT_X4_MASKED_DST, LABORAT_X4_OVERLAY_DST)

generate_laborat_overlay()
