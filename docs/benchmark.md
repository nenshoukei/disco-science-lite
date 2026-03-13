# Benchmark: Basic Lua Operations

Empirical benchmark results for basic Lua operations in the Factorio runtime environment (Lua 5.2.1) on Mac with Apple M2 Max + 32GB RAM.

## Method

Each test case runs N=100,000 iterations, repeated for ROUNDS=10 rounds, with N warm-up iterations before timing.
The profiler measures total time across all rounds, then `p.divide(ROUNDS)` is used to get the average per round.
Results show the average duration per round (N=100,000 ops), and per-op time.

Source: [scripts/runtime/control/benchmark.lua](../scripts/runtime/control/benchmark.lua)

## Test Cases

| Name                 | Code                                                              |
| -------------------- | ----------------------------------------------------------------- |
| Division             | `local _ = 1 / pi`                                                |
| Multiplication       | `local _ = 1 * inv_pi` (pre-computed `inv_pi = 1 / pi`)           |
| Hash-key Access      | `local _ = h_table.x + h_table.y`                                 |
| Array-index Access   | `local _ = a_table[1] + a_table[2]`                               |
| Upvalue              | `local _ = upvalue + upvalue`                                     |
| Local variable       | `local lv = upvalue; local _ = lv + lv`                           |
| Index-based for-loop | `for i = 1, #tbl do local _v = tbl[i] end`                        |
| ipairs() for-loop    | `for k, v in ipairs(tbl) do end`                                  |
| pairs() for-loop     | `for k, v in pairs(tbl) do end`                                   |
| next() while-loop    | `local k, v = next(tbl, nil); while k do k, v = next(tbl, k) end` |

## Results

Run 1:

```
--- Benchmarking 10 cases (N=100000, ROUNDS=10) ---
Division            : Duration: 499.456354ms  (0.00499456ms/op)
Multiplication      : Duration: 508.079863ms  (0.00508080ms/op)
Hash-key Access     : Duration: 502.371013ms  (0.00502371ms/op)
Array-index Access  : Duration: 501.621275ms  (0.00501621ms/op)
Upvalue             : Duration: 505.279633ms  (0.00505280ms/op)
Local variable      : Duration: 499.190687ms  (0.00499191ms/op)
Index-based for-loop: Duration: 503.912942ms  (0.00503913ms/op)
ipairs() for-loop   : Duration: 2749.988375ms  (0.02749988ms/op)
pairs() for-loop    : Duration: 2771.552158ms  (0.02771552ms/op)
next() while-loop   : Duration: 2318.020117ms  (0.02318020ms/op)
```

Run 2:

```
--- Benchmarking 10 cases (N=100000, ROUNDS=10) ---
Division            : Duration: 520.214254ms  (0.00520214ms/op)
Multiplication      : Duration: 504.512279ms  (0.00504512ms/op)
Hash-key Access     : Duration: 509.994750ms  (0.00509995ms/op)
Array-index Access  : Duration: 521.659396ms  (0.00521659ms/op)
Upvalue             : Duration: 497.561742ms  (0.00497562ms/op)
Local variable      : Duration: 503.828667ms  (0.00503829ms/op)
Index-based for-loop: Duration: 505.373596ms  (0.00505374ms/op)
ipairs() for-loop   : Duration: 2765.078821ms  (0.02765079ms/op)
pairs() for-loop    : Duration: 2749.679279ms  (0.02749679ms/op)
next() while-loop   : Duration: 2313.669146ms  (0.02313669ms/op)
```

Run 3:

```
--- Benchmarking 10 cases (N=100000, ROUNDS=10) ---
Division            : Duration: 504.950500ms  (0.00504951ms/op)
Multiplication      : Duration: 501.279321ms  (0.00501279ms/op)
Hash-key Access     : Duration: 517.671975ms  (0.00517672ms/op)
Array-index Access  : Duration: 509.722421ms  (0.00509722ms/op)
Upvalue             : Duration: 514.592950ms  (0.00514593ms/op)
Local variable      : Duration: 506.006442ms  (0.00506006ms/op)
Index-based for-loop: Duration: 507.191513ms  (0.00507192ms/op)
ipairs() for-loop   : Duration: 2741.859537ms  (0.02741860ms/op)
pairs() for-loop    : Duration: 2732.907308ms  (0.02732907ms/op)
next() while-loop   : Duration: 2291.870392ms  (0.02291870ms/op)
```

Note: one "op" for loop cases = one complete iteration over a 3-element table.
Absolute times vary ~5% between runs due to OS CPU scheduling.

## Conclusions

### Multiplication vs. Division

- Differences between runs (<5%) fall within measurement noise.
- **Conclusion:** No meaningful performance difference. Choose based on readability.

### Hash-key Access vs. Array-index Access

- Differences between runs (<5%) fall within measurement noise.
- **Conclusion:** No meaningful performance reason to prefer one over the other. Choose based on readability.

### Upvalue vs. Local Variable

- Differences between runs (<1%) fall within measurement noise.
- **Conclusion:** No need to copy upvalues into locals purely for performance. Choose based on readability.

### For-loop Iteration

This is the largest and most reproducible performance gap found.
The ratios are stable across all 3 runs even though absolute times vary ~5%.

Results for iterating a 3-element table:

| Method               | Run 1  | Run 2  | Run 3  | Ratio vs index-based |
| -------------------- | ------ | ------ | ------ | -------------------- |
| Index-based for-loop | 503ms  | 505ms  | 507ms  | 1.0x (baseline)      |
| next() while-loop    | 2318ms | 2313ms | 2291ms | ~4.5–4.6x slower     |
| ipairs() for-loop    | 2749ms | 2765ms | 2741ms | ~5.4–5.5x slower     |
| pairs() for-loop     | 2771ms | 2749ms | 2732ms | ~5.4–5.5x slower     |

Key findings:

- **Index-based `for i = 1, #tbl`** has virtually zero loop overhead — same ~500ms range as all other non-loop operations.
- **`ipairs` and `pairs`** are ~5.4–5.5x slower due to the generic-for iterator call overhead.
- **`next()` while-loop** is ~15% faster than `ipairs`/`pairs` by avoiding the iterator protocol, but still ~4.5–4.6x slower than index-based.
- **Rule:** Use index-based for-loops for arrays in hot paths. For hash tables, `next()` while-loop is preferable to `pairs()` when performance matters.

## Notes

- Factorio uses standard Lua 5.2.1 (not LuaJIT), so dead code elimination does not occur.
  Assigning to `local _ = expr` still evaluates `expr` fully.
- `math.random()` in Factorio is deterministic (seeded from game state), so benchmarks are reproducible across runs.
