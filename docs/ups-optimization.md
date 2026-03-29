# UPS Optimization in Disco Science Lite

This document describes the technical strategies used to minimize the UPS (Updates Per Second) impact of Disco Science Lite. The mod is designed to handle hundreds of labs with minimal performance overhead, even in mega-bases.

## 1. Visibility-Based Processing (ChunkMap)

The most effective optimization is **not processing what isn't visible**.

While a standard implementation might update every lab in the entire world every single tick, this approach can struggle to scale as your factory grows to hundreds or thousands of labs. Disco Science Lite uses a custom "ChunkMap" to organize labs by their location on the map based on chunks (32x32 tiles).

Every 30 ticks (twice per second), the mod calculates exactly which chunks of the map are currently visible to the active player. Only labs within these visible chunks are added to the "in-view" list. If no one is looking at a lab, it consumes virtually zero CPU time.

Additionally, when the player is in chart mode (the map/radar view), all lab updates are skipped entirely, since overlays are not visible in that view.

## 2. Tiered Update System

To balance responsiveness with performance, the mod separates tasks into three tiers:

- **Viewport Update (Every 30 Ticks):**
    - Checks what technology is currently being researched and updates the available color palette.
    - Checks the player's position and zoom level.
    - Rebuilds the list of in-view labs based on the computed visible chunk range.
    - Skips all further processing if no research is active (all labs invisible).

- **Incremental Status Scan (Every Tick):**
    - Each tick, updates the visible/hidden state of a small batch of in-view labs by checking `entity.status`.
    - The batch size is `ceil(n / 30)`, ensuring all in-view labs are scanned within one 30-tick cycle.
    - This spreads the expensive C-bridge `entity.status` calls evenly across ticks, eliminating the stutter that would occur if all labs were checked at once.
    - On forced full-scan events (e.g., research changes, lab added/removed), all in-view labs are scanned in the same tick.

- **Color Update (Every `color_update_interval` Ticks):**
    - Updates the actual colors of the visible labs using stride iteration.
    - This is the only logic that writes color data to the Factorio engine, and it only operates on the pre-filtered list of visible labs.

## 3. Stride-Based Load Balancing

Writing color data to the Factorio engine is one of the most "expensive" parts of a visual mod. If you zoom out to see 1,000 labs at once, updating all of them in a single tick could cause a noticeable "stutter" (CPU spike).

To prevent this, the mod uses an **Automatic Stride System**. Two parameters are recalculated whenever the number of visible labs changes:

- **`color_update_stride`**: How many labs to skip between each update within a single tick. For example, a stride of 2 updates labs 1, 3, 5, … on tick A and labs 2, 4, 6, … on tick B.
- **`color_update_interval`**: How many ticks to wait between color update calls. This kicks in at extreme lab counts to further reduce per-tick workload.

The mod processes up to `color_update_max_per_call` visible labs per tick (default: 500), and up to `color_update_budget` updates per second (default: 1000). Stride and interval are derived from these budgets automatically.

For example, if you are looking at 1,000 labs:

- The mod will update 500 labs on Tick A.
- The mod will update the other 500 labs on Tick B.
- This continues in a cycle, ensuring that the work is spread evenly over time.

| Visible Labs | Updates per Tick | Update Frequency per Lab | Visual Impact                  |
| ------------ | ---------------- | ------------------------ | ------------------------------ |
| 100          | 100              | Every tick               | Perfectly smooth               |
| 500          | 500              | Every tick               | Perfectly smooth               |
| 1000         | 500              | Every 2nd tick           | Barely noticeable              |
| 3000         | 500              | Every 6th tick           | Slight flicker at extreme zoom |

## 4. Minimizing "Engine Overhead"

Interacting with the Factorio game engine (the "C-Bridge") is slower than running logic inside the mod itself. To keep things fast, the mod caches as much information as possible:

- **Position Caching:** Instead of asking the engine where a player is for every single lab, we ask once per tick and reuse that position for all labs visible to them.
- **Status Caching:** Lab visibility state is tracked in the `overlay.visible` field in Lua. The incremental status scan updates this at a rate of `ceil(n / 30)` labs per tick, avoiding thousands of redundant `entity.status` requests every tick.
- **Color Caching:** Research colors are flattened into a flat number array by `ColorRegistry` and cached in the tick closure. This is only refreshed when the active research changes.
- **Visible State Caching:** The `overlay.visible` field caches the last-known visible state, so the color update loop can skip invisible labs without any C-bridge calls.
