# UPS Optimization in Disco Science Lite

This document describes the technical strategies used to minimize the UPS (Updates Per Second) impact of Disco Science Lite. The mod is designed to handle hundreds of labs with minimal performance overhead.

## 1. Spatial Filtering via ChunkMap

The most effective optimization is **not processing what isn't visible**.

The naive approach of iterating over all labs on every tick scales with the total number of labs ($O(N)$), which is not comfortable with mega-bases. Disco Science Lite iterates over only visible labs for connected players.

To reduce view-port calculation, the mod splits labs into chunks (32x32 tiles) using a custom [ChunkMap](/scripts/runtime/chunk-map.lua) (a three-level table: `surface → chunk_x → chunk_y`). Every 30 ticks, the mod calculates the range of chunks visible to the player's current view. Only labs within these chunks are gathered into a flat list `visible_overlays` for updating their colors by `on_tick` function.

## 2. Tiered Update System

Not all logic needs to run every tick. The mod separates tasks into three frequency-based tiers to balance responsiveness with performance:

- **Heavy Update (Every 30 Ticks):** Checks `entity.status` and `force.current_research`, and rebuilds the `visible_overlays` list by calculating view-port on every connected players.
- **Medium Update (Every 10 Ticks + Events):** Updates player position for each force to make the disco effect follow the player.
- **Hot Update (Every Tick):** Updates lab colors calculated by color functions. Iterates only over the pre-filtered `visible_overlays` list.

## 3. Stride-Based Load Balancing with Auto-Scaling

To handle extreme cases with hundreds of visible labs, the mod uses a stride-based update system that automatically adjusts to the current workload.

Instead of updating every visible lab every tick, the mod updates only `1/N` of the list per tick — cycling through the full list over `N` ticks. This spreads the Lua-to-C bridge cost (the main bottleneck when writing `LuaRenderObject.color`) evenly over time, preventing CPU spikes.

The stride `N` (`current_interval`) is recalculated every 30 ticks:

```
N = max(1, ceil(visible_labs / max_updates_per_tick))
N = min(N, 60)
```

Where `max_updates_per_tick` is the mod setting `Max lab color updates per tick` (default: 500). For example:

| Visible labs | `max_updates_per_tick` | Stride N | Update frequency per lab |
| ------------ | ---------------------- | -------- | ------------------------ |
| 50           | 500                    | 1        | Every tick               |
| 300          | 500                    | 1        | Every tick               |
| 1000         | 500                    | 2        | Every 2 ticks            |
| 1000         | 200                    | 5        | Every 5 ticks            |

On Mac with Apple M2 Max, benchmarks show each `LuaRenderObject.color` write costs approximately 5 μs, so `max_updates_per_tick = 500` corresponds to ~2.5 ms at maximum (when 500+ labs fill the viewport at extreme zoom-out). At typical zoom levels, fewer than 200 labs are visible, keeping the overhead well under 1 ms.
