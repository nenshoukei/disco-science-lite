# UPS Optimization in Disco Science Lite

This document describes the technical strategies used to minimize the UPS (Updates Per Second) impact of Disco Science Lite. The mod is designed to handle hundreds of labs with minimal performance overhead, even in mega-bases.

## 1. Visibility-Based Processing (ChunkMap)

The most effective optimization is **not processing what isn't visible**.

While a standard implementation might update every lab in the entire world every single tick, this approach can struggle to scale as your factory grows to hundreds or thousands of labs. Disco Science Lite uses a custom `ChunkMap` to organize lab overlays (RenderObjects for colorization) by chunk (32x32 tiles), then scans only the chunks that intersect the player's viewport which is updated every 30 ticks.

Additionally, the ChunkMap keeps per-surface outermost chunk bounds. If the player is definitely outside the maximum reachable view area of all labs on that surface, the viewport scan is skipped entirely. In chart mode (map/radar), updates are also skipped.

## 2. Tiered Update System

To balance responsiveness with performance, the mod separates tasks into three tiers:

- **Viewport Update (Every 30 Ticks):**
    - Tracks current research and updates the color palette to match the colors of consumed science packs when research changes.
    - Updates player position and visible chunk range.
    - Updates the in-view overlay list.
    - Skips the rest of the work early when no research is ongoing.

- **Incremental Status Scan (Every Tick):**
    - For each in-view overlay, updates the overlay's visibility depending on whether the lab entity is working or not.
    - Uses a round-robin cursor to iterate over the in-view list with per-tick budget `ceil(n_all_overlays_in_view / 30)`, so all in-view overlays are updated within one 30-tick cycle.

- **Color Update (Every N Ticks):**
    - Applies color animation via M stride iteration over the in-view list, where interval N and stride M are automatically calculated based on the number of visible overlays and the Mod Setting `Animation quality`. (See below)

## 3. Automatic Load Balancing

Writing color data to the Factorio engine is one of the most "expensive" parts of a visual mod. If you zoom out to see 1,000 labs at once, updating all of them in a single tick could cause a noticeable "stutter" (CPU spike).

To prevent this, the mod uses an **automatic stride + interval system**. Parameters are recalculated whenever the visible overlay count changes:

- `stride = clamp(ceil(n_visible_overlays / max_updates), 1, 60)`
- `interval = clamp(ceil(n_visible_overlays / (budget * stride)), 1, 30)`

`budget` and `max_updates` are derived from the runtime preset provided as the Mod Setting `Animation quality`:

| `Animation quality` | `budget` | `max_updates` |
| ------------------- | -------- | ------------- |
| Smooth              | 500      | 1000          |
| Balanced            | 200      | 500           |
| Performance         | 50       | 100           |

Default is `Balanced`.

Example behavior with **Balanced** (`budget=200`, `max_updates=500`):

| `n_visible_overlays` | `stride` | `interval` | Update Frequency per Lab |
| -------------------- | -------- | ---------- | ------------------------ |
| 100                  | 1        | 1          | Every tick               |
| 500                  | 1        | 3          | Every 3 ticks            |
| 1000                 | 2        | 3          | Every 6 ticks            |
| 3000                 | 6        | 3          | Every 18 ticks           |

In this way, when there are fewer labs, each lab is updated more frequently; when there are more labs, each lab is updated less frequently. This flattens per-tick update load and minimizes stutter.
