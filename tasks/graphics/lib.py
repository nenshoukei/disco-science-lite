"""Shared utilities for graphics generation."""

import glob as _glob
import io
import math
import zipfile
from contextlib import contextmanager
from pathlib import Path
from typing import IO, Callable, Iterator

import numpy as np
from PIL import Image
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

ROOT_DIR = Path(__file__).parent.parent.parent
SOURCE_DIR = ROOT_DIR / "tasks/graphics/source"
GRAPHICS_DIR = ROOT_DIR / "graphics"

# Lab light image is useful for generating overlays
LAB_LIGHT_PNG = FACTORIO_DATA / "base/graphics/entity/lab/lab-light.png"
LAB_LIGHT_FRAME_W, LAB_LIGHT_FRAME_H = 216, 194
LAB_LIGHT_FRAMES = 33
LAB_LIGHT_COLS = 11
LAB_LIGHT_ROWS = 3


def fill_black_background(img: Image.Image) -> Image.Image:
    """Paste onto black background to ensure transparent areas are black (0, 0, 0)"""
    bg = Image.new("RGBA", img.size, (0, 0, 0, 0))
    bg.paste(img, mask=img)
    return bg


def rgb_to_grayscale(r: np.ndarray, g: np.ndarray, b: np.ndarray) -> np.ndarray:
    """Convert r, g, b arrays into a grayscale array"""
    # Weighted average same as Pillow's convert L
    return (0.299 * r + 0.587 * g + 0.114 * b).clip(0, 255)


def extract_frame(
    arr: np.ndarray, idx: int, frame_w: int, frame_h: int, cols: int, offset_x: int = 0, offset_y: int = 0, capture_w: int = 0, capture_h: int = 0
) -> np.ndarray:
    """Extract a frame from a grid image"""
    col, row = idx % cols, idx // cols
    left = col * frame_w + offset_x
    right = left + (capture_w or frame_w)
    top = row * frame_h + offset_y
    bottom = top + (capture_h or frame_h)
    return arr[top:bottom, left:right]


def assemble_grid(frames: list[np.ndarray], cols: int) -> np.ndarray:
    """Assemble frames into a grid image"""
    frame_h, frame_w = frames[0].shape[:2]
    rows = math.ceil(len(frames) / cols)
    # Support both 2D (L) and 3D (LA, RGB, RGBA) frames
    sheet_shape = (rows * frame_h, cols * frame_w) + frames[0].shape[2:]
    sheet = np.zeros(sheet_shape, dtype=np.uint8)
    for i, frame in enumerate(frames):
        col, row = i % cols, i // cols
        sheet[row * frame_h : (row + 1) * frame_h, col * frame_w : (col + 1) * frame_w] = frame
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
        top_dirs = set(name.split("/")[0] for name in z.namelist() if "/" in name)
        top_dirs.discard("__MACOSX")  # Some mods have this directory
        if len(top_dirs) != 1:
            raise ValueError(f"Expected one top-level directory in zip, found: {top_dirs}")
        zip_dir = top_dirs.pop()
        yield lambda path: z.open(f"{zip_dir}/{path}")


def save_image(img: Image.Image, dst_path: Path) -> None:
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    optimized = oxipng.optimize_from_memory(buf.getvalue(), level=6, optimize_alpha=True)
    dst_path.parent.mkdir(parents=True, exist_ok=True)
    dst_path.write_bytes(optimized)
    print("Generated", dst_path.relative_to(ROOT_DIR))
