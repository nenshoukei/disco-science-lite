# UPS Optimization Strategy

This document describes the technical strategies used to minimize the UPS (Updates Per Second) impact of Disco Science Lite. The mod is designed to handle hundreds of labs with minimal performance overhead.

## 1. Spatial Filtering via ChunkMap

The most effective optimization is **not processing what isn't visible**.

Factorio mods often iterate over all entities, which scales poorly ($O(N)$ where $N$ is the total number of labs). Disco Science Lite splits labs into chunks using a custom [ChunkMap](/scripts/runtime/chunk-map.lua) (a three-level table: `surface → chunk_x → chunk_y`).

- **View-Port Pruning:** Every 30 ticks, the mod calculates the range of chunks visible to the player's current view. Only labs within these chunks are gathered into a flat `visible_overlays` list.
- **Zero Iteration for Off-screen Labs:** Labs in off-screen chunks are never touched during the `on_tick` loop. The performance cost scales with **visible** labs, not total labs.
- **Multi-Player Deduplication:** When multiple players are connected, a generation counter is used in `get_state_update_function()` to ensure that a chunk visible to multiple players is only processed once per update cycle.

## 2. Tiered Update System

Not all logic needs to run every tick. The mod separates tasks into three frequency-based tiers to balance responsiveness with performance:

- **Heavy Update (Every 30 Ticks):** The `get_state_update_function()` handles the most expensive operations. It checks `entity.status` and `force.current_research`, and performs the primary viewport-to-chunk mapping. This cycle rebuilds the `visible_overlays` list.
- **Medium Update (Every 10 Ticks + Events):** The `get_tracker_update_function()` manages player viewports. It calculates which chunks are currently on-screen. This function is also triggered by events like `on_player_changed_position` to ensure the disco effect activates immediately when a player moves into range.
- **Hot Update (Every Tick):** The `on_tick` handler is strictly limited to color interpolation and the Lua-to-C bridge write to `animation.color`. It only iterates over the pre-filtered `visible_overlays` list, ensuring the minimum possible overhead in the most frequent loop.

## 3. Hot-Path Lua Optimizations

The tick function is a **closure** meticulously optimized for Factorio's Lua environment:

- **Upvalue Capture:** All necessary references (visible list, player positions, color sets) are captured as upvalues during closure creation. This eliminates the need for expensive global or member lookups (`self.xxx`) during the loop.
- **Local Binding:** Within the tick function, upvalues are rebound to local variables. In Lua, local variable access is significantly faster than upvalue or table field access.
- **Array-Only Tables:** All internal data structures are array-like tables. This avoids the overhead of hash-map lookups associated with string keys.
- **Per-Force Caching:** Since most labs on a screen belong to the same force, the mod caches research colors and player positions for the "current" force inside the loop. This typically reduces dozens of table lookups to a single check per tick.

## 4. Stride-Based Load Balancing

To handle extreme cases with hundreds of visible labs, the `Lab update interval` setting (default: 6) provides a final level of load balancing:

- The mod uses a "stride" to update only `1/N` of the visible labs each tick.
- This effectively spreads the Lua-to-C bridge cost across `N` ticks, smoothing out CPU spikes and maintaining a rock-solid 60 UPS even in mega-factories.

## 5. Dynamic Color Function Compilation

Color functions are **dynamically generated and compiled** to eliminate function call overhead:

- **Template Inlining:** Core interpolation logic and animation patterns are merged into a single string template.
- **Hot-Reloadable Load():** The resulting code is compiled via `load()`, producing a flat, highly efficient function that avoids internal branching and nested calls.
- **Embedded Math:** Mathematical constants (e.g., `INV_PI`) are pre-calculated and embedded as literals during the compilation phase.

## 6. Constant Literalization

Even simple table lookups (like `consts.CHUNK_SIZE`) can impact performance in a hot loop. Disco Science Lite uses a build-time script to embed constants as literals:

- **Special Syntax:** Code uses annotations like `32 --[[$CHUNK_SIZE]]`.
- **Build-Time Substitution:** The `make consts` task replaces these values with their definitions from [consts.lua](/scripts/shared/consts.lua).
- **Zero-Cost Access:** This transforms variable lookups into raw literals in the compiled Lua bytecode, which is particularly effective for array indices used throughout the animation loop.
