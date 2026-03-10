# Tick Function — UPS Optimization Strategy

This document describes the technical strategies used to minimize the UPS (Updates Per Second) impact of Disco Science Lite's per-tick animation loop.

## 1. Spatial Filtering via ChunkMap

The most effective optimization is **not processing what isn't visible**.

Factorio mods often iterate over all entities, which scales poorly ($O(N)$ where $N$ is the total number of labs). Disco Science Lite splits labs into chunks using a custom [ChunkMap](/scripts/runtime/chunk-map.lua) (a three-level table: `surface → chunk_x → chunk_y`). A chunk is 32x32 tiles segment used as Factorio standard.

- **View-Port Pruning:** Every 30 ticks, the mod calculates the range of chunks visible to the player's current view. Only labs within these chunks are gathered into a flat `visible_overlays` list.
- **Zero Iteration for Off-screen Labs:** Labs in off-screen chunks are never touched during the `on_tick` loop. The performance cost scales with **visible** labs, not total labs.

## 2. Hot-Path Lua Optimizations

The tick function returned by `get_tick_function()` is a **closure** optimized for the LuaJIT-less environment of Factorio:

- **Upvalue Capture:** All dependencies (visible list, player position, color sets) are captured as upvalues. This avoids expensive global or table lookups (`self.xxx`) during the loop.
- **Local Binding:** At the start of each tick, upvalues are rebound to local variables. In Lua, accessing local variables is faster than accessing upvalues or table fields.
- **Array Tables:** All tables used in the tick function are array-like tables. No hash-key access to tables (`tbl.key`) which is slower than index access (`tbl[1]`).
- **C-Bridge Write Minimization:** The dominant cost in Factorio modding is the Lua-to-C bridge (writing to `LuaEntity` or `LuaRenderObject`).
    - The `on_tick` loop _only_ performs the write to `animation.color`.
    - Visibility and status checks (`entity.valid`, `entity.status`) are offloaded to the slower `on_nth_tick(30)` cycle.
- **Stride-Based Load Balancing:** The `lab-update-interval` setting allows spreading the C-bridge writes across multiple ticks (e.g., updating only 1/6 of visible labs each tick), which is the final lever for extreme UPS stability.

## 3. Inlined Color Function Templates

To avoid the overhead of function calls and repeated interpolation logic inside the hot loop, color functions are **dynamically compiled** from templates in [color-functions.lua](/scripts/runtime/color-functions.lua).

- **Template Inlining:** The core interpolation logic (circular color picking and linear transition) is defined as a string template. Specific animation patterns (Radial, Angular, etc.) are injected into this template.
- **Dynamic Compilation:** The resulting Lua code is compiled using `load()`. This generates a single, flat function where the animation logic and interpolation are seamless, eliminating multiple internal function calls per lab.
- **Pre-computed Constants:** Constants like `INV_PI` or `INV_TWO_PI` are embedded as numeric literals during compilation.
