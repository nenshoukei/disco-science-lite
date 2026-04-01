"""Generate overlay graphics for disco-science-lite mod."""

import os
import sys
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

sys.path.insert(0, str(Path(__file__).parent))

from mods.factorio import generate_lab_images, generate_general_overlay, generate_biolab_images
from mods.laborat import generate_laborat_images
from mods.Krastorio2 import generate_krastorio2_images
from mods.aai_industry import generate_aai_industry_images
from mods.hurricane import (
    generate_hurricane_arc_furnace_images,
    generate_hurricane_fusion_reactor_images,
    generate_hurricane_research_center_images,
    generate_hurricane_photometric_lab_images,
)
from mods.corrundum import generate_corrundum_images

# mod name -> list of generator functions
MOD_GENERATORS: dict[str, list] = {
    "factorio": [generate_lab_images, generate_general_overlay, generate_biolab_images],
    "laborat": [generate_laborat_images],
    "Krastorio2": [generate_krastorio2_images],
    "aai-industry": [generate_aai_industry_images],
    "hurricane": [
        generate_hurricane_arc_furnace_images,
        generate_hurricane_fusion_reactor_images,
        generate_hurricane_research_center_images,
        generate_hurricane_photometric_lab_images,
    ],
    "corrundum": [generate_corrundum_images],
}

mod_filter_env = os.environ.get("MOD")
if mod_filter_env:
    requested = {m.strip() for m in mod_filter_env.split(",")}
    unknown = requested - MOD_GENERATORS.keys()
    if unknown:
        print(f"Unknown mod(s): {', '.join(sorted(unknown))}", file=sys.stderr)
        print(f"Available: {', '.join(MOD_GENERATORS.keys())}", file=sys.stderr)
        sys.exit(1)
    selected_generators = [fn for mod in requested for fn in MOD_GENERATORS[mod]]
else:
    selected_generators = [fn for fns in MOD_GENERATORS.values() for fn in fns]

with ThreadPoolExecutor() as executor:
    futures = [executor.submit(fn) for fn in selected_generators]
    for future in as_completed(futures):
        future.result()  # re-raise any exceptions
