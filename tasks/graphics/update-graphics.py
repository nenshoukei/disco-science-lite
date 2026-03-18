"""Generate overlay graphics for disco-science-lite mod."""

import sys
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

sys.path.insert(0, str(Path(__file__).parent))

from mods.factorio import generate_lab_images, generate_general_overlay, generate_biolab_images
from mods.laborat import generate_laborat_images
from mods.Krastorio2 import generate_krastorio2_images
from mods.aai_industry import generate_aai_industry_images

with ThreadPoolExecutor() as executor:
    futures = [
        executor.submit(generate_lab_images),
        executor.submit(generate_general_overlay),
        executor.submit(generate_biolab_images),
        executor.submit(generate_laborat_images),
        executor.submit(generate_krastorio2_images),
        executor.submit(generate_aai_industry_images),
    ]
    for future in as_completed(futures):
        future.result()  # re-raise any exceptions
