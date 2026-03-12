# UPS Optimization in Disco Science Lite

This document describes the technical strategies used to minimize the UPS (Updates Per Second) impact of Disco Science Lite. The mod is designed to handle hundreds of labs with minimal performance overhead.

## 1. Spatial Filtering via ChunkMap

The most effective optimization is **not processing what isn't visible**.

Factorio mods often iterate over all entities, which scales poorly ($O(N)$ where $N$ is the total number of labs). Disco Science Lite splits labs into chunks using a custom [ChunkMap](/scripts/runtime/chunk-map.lua) (a three-level table: `surface → chunk_x → chunk_y`).

- **View-Port Pruning:** Every 30 ticks, the mod calculates the range of chunks visible to the player's current view. Only labs within these chunks are gathered into a flat `visible_overlays` list.
- **Zero Iteration for Off-screen Labs:** Labs in off-screen chunks are never touched during the `on_tick` loop. The performance cost scales with **visible** labs, not total labs.
- **Multi-Player Deduplication:** When multiple players are connected, a generation counter ensures that a chunk visible to multiple players is only processed once per update cycle.

## 2. Tiered Update System

Not all logic needs to run every tick. The mod separates tasks into three frequency-based tiers to balance responsiveness with performance:

- **Heavy Update (Every 30 Ticks):** Checks `entity.status` and `force.current_research`, and rebuilds the `visible_overlays` list via viewport-to-chunk mapping.
- **Medium Update (Every 10 Ticks + Events):** Recalculates which chunks are on-screen. Also triggered by events like `on_player_changed_position` to ensure the disco effect activates immediately when a player moves into range.
- **Hot Update (Every Tick):** Strictly limited to color interpolation and writing `animation.color`. Iterates only over the pre-filtered `visible_overlays` list.

## 3. Hot-Path Lua Optimizations

The tick function is a **closure** meticulously optimized for Factorio's Lua environment.

### Closure & Local Variable Binding

- **Upvalue Capture:** All necessary references (visible list, player positions, color sets) are captured as upvalues at closure creation, eliminating global or member lookups (`self.xxx`) during the loop.
- **Local Binding:** Within the tick function, upvalues are rebound to local variables. In Lua, local variable access is significantly faster than upvalue or table field access.
- **Array-Only Tables:** All internal data structures are array-like tables, avoiding the overhead of hash-map lookups associated with string keys.
- **Per-Force Caching:** Since most labs on a screen belong to the same force, research colors and player positions are cached for the "current" force inside the loop. This typically reduces dozens of table lookups to a single check per tick.

### Mathematical Function Choices

In Factorio's Lua environment, even standard library function calls carry significant overhead compared to inline arithmetic. Benchmarks run inside the Factorio runtime (100,000+ iterations via `game.create_profiler()`) guided these choices:

- **Avoid `math.abs`, `math.max`, `math.floor`:** Replaced with inline equivalents (`x < 0 and -x or x`, `a > b and a or b`, `t - t % 1`). These are meaningfully faster in a hot loop.
- **`math.atan2` vs. Diamond Angle:** For full 360° radial calculations, `math.atan2` (C-implemented) is faster and more accurate than a Lua-based quadrant-branching approximation. However, for a single-quadrant case like the Kaleidoscope pattern, a simple division (`dy / (dx + dy)`) beats `atan2`.
- **Multiply by inverse instead of divide:** `val * (1/10)` is faster than `val / 10` in a hot loop. Constants are pre-calculated as upvalues.
- **Pre-scale loop invariants:** Values that can be pre-computed once (e.g., scaling `phase_speed` by `1/40`) are applied before the loop rather than inside every iteration.

## 4. Stride-Based Load Balancing with Auto-Scaling

To handle extreme cases with hundreds of visible labs, the mod uses a stride-based update system that automatically adjusts to the current workload.

Instead of updating every visible lab every tick, the mod updates only `1/N` of the list per tick — cycling through the full list over `N` ticks. This spreads the Lua-to-C bridge cost (the main bottleneck when writing `animation.color`) evenly over time, preventing CPU spikes.

The stride `N` (`current_interval`) is recalculated every 30 ticks:

```
N = max(1, ceil(visible_labs / max_updates_per_tick))
N = min(N, 60)
```

Where `max_updates_per_tick` is a mod setting (default: 200). For example:

| Visible labs | Budget (default 200) | Stride N | Update frequency per lab |
| ------------ | -------------------- | -------- | ------------------------ |
| 50           | 200                  | 1        | Every tick               |
| 300          | 200                  | 2        | Every 2 ticks            |
| 1000         | 200                  | 5        | Every 5 ticks            |
| 1000         | 500                  | 2        | Every 2 ticks            |

The `Max lab color updates per tick` setting lets you tune this budget to your PC's performance — raising it on a fast machine gives smoother color transitions, while lowering it reduces CPU load.

## 5. Dynamic Color Function Compilation

Color functions are **dynamically generated and compiled** to eliminate function call overhead:

- **Template Inlining:** Core interpolation logic and animation patterns are merged into a single string template.
- **`load()` Compilation:** The resulting code is compiled via `load()`, producing a flat, highly efficient function that avoids internal branching and nested calls.
- **Embedded Math:** Mathematical constants (e.g., `INV_PI`) are pre-calculated and embedded as literals during the compilation phase.

## 6. Constant Literalization

Even simple table lookups (like `consts.CHUNK_SIZE`) can impact performance in a hot loop. Disco Science Lite uses a build-time script to embed constants as literals:

- **Special Syntax:** Code uses annotations like `32 --[[$CHUNK_SIZE]]`.
- **Build-Time Substitution:** The `make consts` task replaces these values with their definitions from [consts.lua](/scripts/shared/consts.lua).
- **Zero-Cost Access:** This transforms variable lookups into raw literals in the compiled Lua bytecode, particularly effective for array indices used throughout the animation loop.
