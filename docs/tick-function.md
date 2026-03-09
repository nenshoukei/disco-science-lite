# Tick Function — Technical Notes

This document describes the UPS optimization strategy used in Disco Science Lite's per-tick color update loop.

## Overview

Disco Science Lite colorizes lab entities by updating a `LuaRenderObject` overlay each tick. The naive approach — iterating over all labs every tick and writing a new color — is expensive at scale. The tick function applies several strategies to reduce this cost.

## Chunk-Based Spatial Indexing

Labs are indexed in a [ChunkMap](/scripts/runtime/chunk-map.lua): a three-level table keyed by `surface_index → chunk_x → chunk_y`, where each cell holds an array of `LabOverlay` objects for that chunk.

Each tick, only chunks that overlap the player's current viewport are iterated. Labs in off-screen chunks are skipped entirely, making the per-tick cost proportional to visible labs rather than total labs.

The player viewport (`player_view`) is updated every 10 ticks via `on_nth_tick(10)`. There is no zoom-change event in Factorio, so periodic polling is used instead.

## Stride-Based Iteration

Even within visible chunks, not every lab is updated every tick. A stride-based scheme spreads the work across `STRIDE` ticks: on each tick, only labs at positions `stride_offset, stride_offset + STRIDE, stride_offset + 2*STRIDE, ...` are processed. `stride_offset` increments each tick and wraps around.

This reduces per-tick work by a factor of `STRIDE` compared to a full sweep, while still updating every lab once per `STRIDE` ticks.

## Tick Function Structure

The tick function is returned by `LabOverlayRenderer:get_tick_function()` as a closure. All hot-path values (chunk map, player view, current research colors, stride state, etc.) are captured as upvalues — no table lookups are needed on the hot path.

## Cached Visibility

Each `LabOverlay` caches whether it is currently visible. Writing `animation.color` across the Lua–C bridge is expensive, so invisible labs are skipped without a C bridge read.

Visibility state is refreshed every 30 ticks by `update_overlay_states()`, which also reads `entity.status` to check whether each lab is active.

## Cached Research State

The current technology being researched (`player_force.current_research`) is read every 30 ticks by `update_overlay_states()`, not every tick. The color set for that research is cached and reused on each tick.

If no research is active (`current_research_colors == nil`), the tick function returns early — no color writes occur.

## C Bridge Write Cost

The dominant remaining cost is `animation.color = color` — a write through the Lua–C bridge (`__newindex = [C]`). This is unavoidable for every visible, active lab that is updated on a given tick. All other optimizations exist to minimize how often this write occurs.
