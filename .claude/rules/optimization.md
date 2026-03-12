---
paths: ["scripts/runtime/**/*.lua"]
description: Optimization strategies discovered through empirical benchmarking within the Factorio runtime environment
---

# Factorio Lua (5.2.1) Optimization Rules

This document outlines the optimization strategies discovered through empirical benchmarking within the Factorio runtime environment.

## 1. Function Call Overhead

In Factorio's Lua environment, the overhead of a function call (even for standard library functions) is significantly higher than the cost of basic arithmetic operations.

### Standard Library vs. Inline Operators

- **Rule:** Prefer inline operators and Lua idioms over `math.*` function calls for simple operations.
- **Example (Absolute Value):**
    - ❌ `local val = math.abs(x)` (Slow)
    - ✅ `local val = x < 0 and -x or x` (Fast)
- **Example (Minimum/Maximum):**
    - ❌ `local val = math.max(a, b)` (Slow)
    - ✅ `local val = a > b and a or b` (Fast)

### The "Floor" Operator Trick

- **Rule:** Use the modulo operator trick to replace `math.floor`.
- **Example:**
    - ❌ `local i = math.floor(t)` (Slow)
    - ✅ `local f = t % 1; local i = t - f` (Fast)
    - Note: `t % 1` gives the fractional part, and `t - t % 1` gives the floor (for positive numbers).

## 2. Geometry & Distance Calculations

While C-implemented functions like `math.sqrt` or `math.atan2` are efficient, the number of calls matters.

### Sqrt vs. Manhattan Distance

- **Rule:** Use Manhattan distance (`abs(dx) + abs(dy)`) or Chebyshev distance (`max(abs(dx), abs(dy))`) instead of Euclidean distance (`sqrt(dx^2 + dy^2)`) if exact circularity is not required.
- **Factorio Benchmark Result:**
    - Euclidean (Sqrt): ~1000ms per 100k calls.
    - Manhattan (Inline): ~500ms per 100k calls.

### Atan2 vs. Diamond Angle

- **Rule:** For full 360-degree radial symmetry, `math.atan2` is faster and more accurate than a complex Lua-based quadrant-branching approximation (Diamond Angle).
- **Caveat:** If you only need a single quadrant (e.g., Kaleidoscope), a simple division `dy / (dx + dy)` is faster than a full `atan2` call.

## 3. Benchmarking Methodology

Never trust local Lua environment benchmarks (e.g., standalone Lua 5.2/5.4) for Factorio performance.

- **Rule:** Always benchmark within the Factorio runtime using `game.create_profiler()`.
- **Rule:** Use `player.request_translation(profiler)` to extract results, as `tostring(profiler)` does not provide data.
- **Rule:** Perform at least 100,000 iterations to drown out background noise and get stable results.

## 4. Constant Pre-calculation

- **Rule:** Multiply by an inverse constant instead of dividing by a literal.
- **Example:**
    - ❌ `t = val / 10`
    - ✅ `local INV_10 = 1/10; t = val * INV_10` (Faster as it avoids division in the hot loop)
