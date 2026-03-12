---
paths: ["scripts/runtime/**/*.lua"]
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

## 2. Pre-scaling Loop Invariants

- **Rule:** Pre-scale values outside of high-frequency loops (like the tick function) to avoid redundant operations inside hot code paths.
- **Example (Phase Scaling):**
    - ❌ Multiplying `phase * INV_40` inside every color function call.
    - ✅ Pre-scaling `phase_speed` by `1/40` in the tick function once, so `phase` is already at the correct scale for all functions.

## 3. Constant Pre-calculation

- **Rule:** Multiply by an inverse constant instead of dividing by a literal.
- **Example:**
    - ❌ `t = val / 10`
    - ✅ `local INV_10 = 1/10; t = val * INV_10` (Faster as it avoids division in the hot loop)
