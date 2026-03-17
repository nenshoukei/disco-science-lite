"""Generate overlay graphics for disco-science-lite mod."""

import glob as _glob
import io
import math
import zipfile
from concurrent.futures import ThreadPoolExecutor, as_completed
from contextlib import contextmanager
from pathlib import Path
from typing import IO, Callable, Iterator

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

def make_mask_frame(img: np.ndarray, alpha: np.ndarray, brightness: float = 0.5) -> np.ndarray:
    """Return LA frame where alpha controls blending (0=transparent, 255=fully replace with gray).
    alpha: bool array for binary mask (True→255, False→0),
           or float/int array (0-255) for soft proportional blend."""
    r = img[:, :, 0].astype(np.float32)
    g = img[:, :, 1].astype(np.float32)
    b = img[:, :, 2].astype(np.float32)
    gray = (rgb_to_grayscale(r, g, b) * brightness).clip(0, 255).astype(np.uint8)
    if alpha.dtype == bool:
        alpha_u8 = np.where(alpha, np.uint8(255), np.uint8(0))
    else:
        alpha_u8 = np.clip(alpha, 0, 255).astype(np.uint8)
    return np.stack([gray, alpha_u8], axis=-1)

@contextmanager
def open_mod_zip(glob_pattern: Path) -> Iterator[Callable[[str], IO[bytes]]]:
    """Find the latest matching zip, auto-detect its top-level directory, and yield
    a callable that opens files by path relative to that directory."""
    zips = sorted(_glob.glob(str(glob_pattern)))
    if not zips:
        raise FileNotFoundError(f"Zip not found at: {glob_pattern}")
    with zipfile.ZipFile(zips[-1]) as z:
        top_dirs = {name.split("/")[0] for name in z.namelist() if "/" in name}
        if len(top_dirs) != 1:
            raise ValueError(f"Expected one top-level directory in zip, found: {top_dirs}")
        zip_dir = top_dirs.pop()
        yield lambda path: z.open(f"{zip_dir}/{path}")

def save_image(img: Image.Image, dst_path: Path) -> None:
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    optimized = oxipng.optimize_from_memory(buf.getvalue())
    dst_path.write_bytes(optimized)
    print("Generated", dst_path)

# --- Lab ---

LAB_LIGHT_SRC = FACTORIO_DATA / "base/graphics/entity/lab/lab-light.png"

LAB_OVERLAY_DST = GRAPHICS_DIR / "factorio/lab-overlay.png"

def generate_lab_images():
    light = np.array(Image.open(LAB_LIGHT_SRC).convert("L")) # Grayscaled
    overlay = (light * 1.5).clip(0, 255) # Brightening
    save_image(Image.fromarray(overlay.astype(np.uint8), "L"), LAB_OVERLAY_DST)

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
    gradient = np.clip(1.0 - np.divide(dist, GENERAL_RADIUS), 0.0, 1.0) ** GENERAL_FALLOFF
    save_image(Image.fromarray((gradient * 255.0).round().astype(np.uint8), "L"), GENERAL_OVERLAY_DST)

# --- Biolab ---

BIOLAB_LIGHT_SRC = FACTORIO_DATA / "space-age/graphics/entity/biolab/biolab-lights.png"

BIOLAB_OVERLAY_DST = GRAPHICS_DIR / "factorio/biolab-overlay.png"

def generate_biolab_images():
    light = np.array(Image.open(BIOLAB_LIGHT_SRC).convert("L")).astype(np.float32) # Grayscaled
    light = np.clip(light * 4.0, 0, 255) # Strong brightening

    # Additive-blend a blurred version for glow effect — apply blur once on the full sheet.
    light_blurred = np.array(Image.fromarray(light.astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(radius=12))).astype(np.float32)
    light = np.clip(light + light_blurred * 1.5, 0, 255)

    save_image(Image.fromarray(light.astype(np.uint8), "L"), BIOLAB_OVERLAY_DST)

# --- LabOMatic (laborat) ---

LABORAT_SRC = ROOT_DIR.parent / "LabOMatic_*.zip"
LABORAT_FRAME_W, LABORAT_FRAME_H = 150, 150
LABORAT_X4_FRAME_W, LABORAT_X4_FRAME_H = 600, 600
LABORAT_FRAMES = 30
LABORAT_COLS = 10

LABORAT_DST_DIR = GRAPHICS_DIR / "laborat"
LABORAT_MASK_DST        = LABORAT_DST_DIR / "lab_albedo_anim-mask.png"
LABORAT_OVERLAY_DST     = LABORAT_DST_DIR / "lab_albedo_anim-overlay.png"
LABORAT_X4_MASK_DST     = LABORAT_DST_DIR / "lab_albedo_anim_x4-mask.png"
LABORAT_X4_OVERLAY_DST  = LABORAT_DST_DIR / "lab_albedo_anim_x4-overlay.png"

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

# --- Krastorio2 ---

KRASTORIO2_ASSETS_SRC = ROOT_DIR.parent / "Krastorio2Assets_*.zip"

K2_ANIM_FRAME_W, K2_ANIM_FRAME_H = 520, 500
K2_ANIM_FRAME_SHIFT = (0, -0.1 * 64) # shift = { 0.0, -0.1 }, scale=0.5 → tiles * 32 / 0.5

K2_GLOW_LIGHT_PATH = "buildings/singularity-lab/singularity-lab-glow-light.png"
K2_GLOW_LIGHT_FRAME_W, K2_GLOW_LIGHT_FRAME_H = 153, 117
K2_GLOW_LIGHT_FRAME_SHIFT = (0, -0.8 * 64) # shift = { 0, -0.8 }, scale=0.5 → tiles * 32 / 0.5
K2_GLOW_LIGHT_COLS = 6

K2_FRAMES = 60

K2_DST_DIR = GRAPHICS_DIR / "Krastorio2"
K2_OVERLAY_DST = K2_DST_DIR / "singularity-lab-overlay.png"

def generate_krastorio2_images():
    with open_mod_zip(KRASTORIO2_ASSETS_SRC) as open_file:
        with open_file(K2_GLOW_LIGHT_PATH) as f:
            light_img = Image.open(f).convert("RGBA")

    light = np.array(fill_black_background(light_img).convert("L")).astype(np.float32)

    static_overlay = np.zeros((K2_ANIM_FRAME_H, K2_ANIM_FRAME_W), dtype=np.float32)
    for i in range(K2_FRAMES):
        light_frame = extract_frame(light, i, K2_GLOW_LIGHT_FRAME_W, K2_GLOW_LIGHT_FRAME_H, K2_GLOW_LIGHT_COLS)
        sized = resize_mask(light_frame, K2_ANIM_FRAME_W, K2_ANIM_FRAME_H, K2_ANIM_FRAME_SHIFT, K2_GLOW_LIGHT_FRAME_SHIFT)
        static_overlay = np.maximum(static_overlay, sized)

    static_overlay = np.clip(static_overlay * 0.8, 0, 255)
    save_image(Image.fromarray(static_overlay.astype(np.uint8), "L"), K2_OVERLAY_DST)

# --- main ---

with ThreadPoolExecutor() as executor:
    executor.submit(generate_lab_images)
    executor.submit(generate_general_overlay)
    executor.submit(generate_biolab_images)
    executor.submit(generate_laborat_images)
    executor.submit(generate_krastorio2_images)
