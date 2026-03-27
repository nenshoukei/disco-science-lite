# UPS Optimization in Disco Science Lite

This document describes the technical strategies used to minimize the UPS (Updates Per Second) impact of Disco Science Lite. The mod is designed to handle hundreds of labs with minimal performance overhead, even in mega-bases.

## 1. Visibility-Based Processing (ChunkMap)

The most effective optimization is **not processing what isn't visible**.

While a standard implementation might update every lab in the entire world every single tick, this approach can struggle to scale as your factory grows to hundreds or thousands of labs. Disco Science Lite uses a custom "ChunkMap" to organize labs by their location on the map based on chunks (32x32 tiles).

Every 30 ticks (twice per second), the mod calculates exactly which chunks of the map are currently visible to active players. Only labs within these visible chunks are added to the "Hot Update" list. If no one is looking at a lab, it consumes virtually zero CPU time.

When multiple players are looking at the same chunk, the mod detects overlapping viewports and checks the same chunk only once per cycle, rather than once per player.

## 2. Tiered Update System

To balance responsiveness with performance, the mod separates tasks into two main frequency tiers:

- **Heavy Update (Every 30 Ticks):**
    - Checks what technology is currently being researched and updates the available color palette.
    - Checks each lab's status (e.g., if it's working or has low power).
    - Rebuilds the list of visible labs based on player positions and zoom levels.
    - Recalculates the load-balancing "Stride" (see below).

- **Hot Update (Every Tick):**
    - Updates the actual colors of the visible labs.
    - This is the only logic that runs 60 times per second, and it only operates on the pre-filtered list of visible labs.

## 3. Stride-Base Load Balancing

Writing color data to the Factorio engine is one of the most "expensive" parts of a visual mod. If you zoom out to see 1,000 labs at once, updating all of them in a single tick could cause a noticeable "stutter" (CPU spike).

To prevent this, the mod uses an **Automatic Stride System**. The mod processes up to 500 visible labs per tick, and automatically spreads the remaining updates over subsequent ticks.

For example, if you are looking at 1,000 labs:

- The mod will update 500 labs on Tick A.
- The mod will update the other 500 labs on Tick B.
- This continues in a cycle, ensuring that the work is spread evenly over time.

| Visible Labs | Max Updates per Tick | Update Frequency per Lab | Visual Impact                  |
| ------------ | -------------------- | ------------------------ | ------------------------------ |
| 100          | 500                  | Every tick               | Perfectly smooth               |
| 500          | 500                  | Every tick               | Perfectly smooth               |
| 1000         | 500                  | Every 2nd tick           | Barely noticeable              |
| 3000         | 500                  | Every 6th tick           | Slight flicker at extreme zoom |

## 4. Minimizing "Engine Overhead"

Interacting with the Factorio game engine (the "C-Bridge") is slower than running logic inside the mod itself. To keep things fast, the mod caches as much information as possible:

- **Position Caching:** Instead of asking the engine where a player is for every single lab, we ask once per player per tick and reuse that position for all labs visible to them.
- **Status Caching:** Lab status and research colors are stored in memory and only refreshed during the "Heavy Update" (every 30 ticks), avoiding thousands of redundant requests to the game engine every tick.
