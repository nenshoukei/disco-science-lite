# Benchmark: Basic Lua Operations

Empirical benchmark results for basic Lua operations in the Factorio runtime environment (Lua 5.2.1).

## Method

Each test case runs N iterations, repeated for ROUNDS=5 rounds, with N warm-up iterations before timing.
The profiler measures total time across all rounds, then `profiler.divide(ROUNDS)` is used to get the average per round.
The `Duration` shown in results is this average-per-round value (time for N operations).

- N = 5,000,000 for arithmetic, variable, table, and insert tests
- N = 100,000 for loop tests (one iteration = one full pass over a 100-element table)

Source: [scripts/runtime/command/ds-bench.lua](../scripts/runtime/command/ds-bench.lua)

## Test Cases

| Category | Name                 | Code                                                              |
| -------- | -------------------- | ----------------------------------------------------------------- |
| division | 1 / pi               | `local _ = 1 / pi`                                                |
| division | 1 \* inv_pi          | `local _ = 1 * inv_pi` (pre-computed `inv_pi = 1 / pi`)           |
| floor    | math.floor(n)        | `local _ = math.floor(n)`                                         |
| floor    | n = n - n % 1        | `local _ = n - n % 1`                                             |
| abs      | math.abs(n)          | `local _ = math.abs(n)`                                           |
| abs      | n < 0 and -n or n    | `local _ = n < 0 and -n or n`                                     |
| max      | math.max(n, m)       | `local _ = math.max(n, m)`                                        |
| max      | n > m and n or m     | `local _ = n > m and n or m`                                      |
| min      | math.min(n, m)       | `local _ = math.min(n, m)`                                        |
| min      | n < m and n or m     | `local _ = n < m and n or m`                                      |
| var      | Upvalue              | `local _ = upvalue + upvalue + upvalue`                           |
| var      | Local variable       | `local lv = upvalue; local _ = lv + lv + lv`                      |
| table    | Hash-key Access      | `local _ = h_table["i1"] + h_table["i50"] + h_table["i100"]`      |
| table    | Array-index Access   | `local _ = a_table[1] + a_table[50] + a_table[100]`               |
| loop     | Index-based for-loop | `for i = 1, #tbl do local _v = tbl[i] end`                        |
| loop     | ipairs() for-loop    | `for k, v in ipairs(tbl) do end`                                  |
| loop     | pairs() for-loop     | `for k, v in pairs(tbl) do end`                                   |
| loop     | next() while-loop    | `local k, v = next(tbl, nil); while k do k, v = next(tbl, k) end` |
| insert   | table.insert()       | `table.insert(tbl, v)`                                            |
| insert   | tbl[#tbl + 1]        | `tbl[#tbl + 1] = v`                                               |
| insert   | tbl[counter]         | `tbl[counter] = v; counter = counter + 1`                         |

Notes:

- Factorio uses standard Lua 5.2.1 (not LuaJIT), so dead code elimination does not occur.
- Insert tests use a table pre-filled with 1,000 elements; `setup_each` resets the table to 1,000 elements before each op, so the table stays at ~1,001 elements throughout.
- Methods like `math.floor` or `table.insert` are precached as local variables.

## Results

The `Duration` column is the Factorio profiler output: average time per round (covering N operations).

### Mac (Apple M2 Max + 32 GB RAM)

| Category | Name                 | Duration               |
| -------- | -------------------- | ---------------------- |
| division | 1 / pi               | Duration: 103.041067ms |
| division | 1 \* inv_pi          | Duration: 103.222208ms |
| floor    | math.floor(n)        | Duration: 156.583200ms |
| floor    | n = n - n % 1        | Duration: 121.272733ms |
| abs      | math.abs(n)          | Duration: 156.642750ms |
| abs      | n < 0 and -n or n    | Duration: 132.708217ms |
| max      | math.max(n, m)       | Duration: 178.913100ms |
| max      | n > m and n or m     | Duration: 116.655000ms |
| min      | math.min(n, m)       | Duration: 178.783184ms |
| min      | n < m and n or m     | Duration: 130.327475ms |
| var      | Upvalue              | Duration: 124.544109ms |
| var      | Local variable       | Duration: 110.167558ms |
| table    | Hash-key Access      | Duration: 174.520958ms |
| table    | Array-index Access   | Duration: 247.622575ms |
| loop     | pairs() for-loop     | Duration: 268.393333ms |
| loop     | ipairs() for-loop    | Duration: 266.413800ms |
| loop     | next() while-loop    | Duration: 365.074808ms |
| loop     | Index-based for-loop | Duration: 119.435492ms |
| insert   | table.insert()       | Duration: 428.499283ms |
| insert   | tbl[#tbl + 1]        | Duration: 375.645108ms |
| insert   | tbl[counter]         | Duration: 303.710383ms |

### Steam Deck

| Category | Name                 | Duration               |
| -------- | -------------------- | ---------------------- |
| division | 1 / pi               | Duration: 178.537843ms |
| division | 1 \* inv_pi          | Duration: 147.529225ms |
| floor    | math.floor(n)        | Duration: 231.706881ms |
| floor    | n = n - n % 1        | Duration: 184.846380ms |
| abs      | math.abs(n)          | Duration: 221.870867ms |
| abs      | n < 0 and -n or n    | Duration: 198.606211ms |
| max      | math.max(n, m)       | Duration: 250.140665ms |
| max      | n > m and n or m     | Duration: 179.281851ms |
| min      | math.min(n, m)       | Duration: 252.023193ms |
| min      | n < m and n or m     | Duration: 193.020422ms |
| var      | Upvalue              | Duration: 175.613131ms |
| var      | Local variable       | Duration: 160.157931ms |
| table    | Hash-key Access      | Duration: 311.706177ms |
| table    | Array-index Access   | Duration: 567.518458ms |
| loop     | pairs() for-loop     | Duration: 438.656317ms |
| loop     | ipairs() for-loop    | Duration: 343.757906ms |
| loop     | next() while-loop    | Duration: 627.008218ms |
| loop     | Index-based for-loop | Duration: 211.895651ms |
| insert   | table.insert()       | Duration: 639.911309ms |
| insert   | tbl[#tbl + 1]        | Duration: 564.340852ms |
| insert   | tbl[counter]         | Duration: 502.906115ms |

## Conclusions

### Arithmetic Operations

**Division vs. Multiplication:** On Mac, no meaningful difference. On Steam Deck, pre-computing `inv_pi` gives a ~1.2x speedup — suggesting the division penalty is more pronounced on lower-power hardware.

**Integer Floor:** `n - n % 1` is ~1.25–1.3x faster than `math.floor(n)` on both platforms.

### Standard Library vs. Inline Logic

Calling standard library functions has overhead compared to equivalent inline logic, though the margin is smaller than previously measured.

| Operation      | Standard Library | Inline Equivalent   | Mac ratio | Steam Deck ratio |
| -------------- | ---------------- | ------------------- | --------- | ---------------- |
| Absolute Value | `math.abs(n)`    | `n < 0 and -n or n` | ~1.2x     | ~1.1x            |
| Maximum        | `math.max(n, m)` | `n > m and n or m`  | ~1.5x     | ~1.4x            |
| Minimum        | `math.min(n, m)` | `n < m and n or m`  | ~1.4x     | ~1.3x            |

**Rule:** In hot paths, prefer inline conditional logic over `math.*` functions for abs/max/min.

### Hash-key Access vs. Array-index Access

**Hash-key access is faster** on both platforms. On Mac the margin is moderate (~1.4x); on Steam Deck it is substantial (~1.8x). This is likely due to array access triggering table resize probing or cache behavior at certain sizes.

**Rule:** When storing values accessed by fixed string keys vs. sequential integers, hash-key access is no slower and may be faster.

### Upvalue vs. Local Variable

Local variables are marginally faster (~1.1–1.13x) than upvalues. The difference is small but consistent.

### For-loop Iteration

Results for iterating a 100-element table (N=100,000 full iterations):

| Method               | Mac   | Steam Deck | Mac ratio vs index | Deck ratio vs index |
| -------------------- | ----- | ---------- | ------------------ | ------------------- |
| Index-based for-loop | 119ms | 211ms      | 1.0x (baseline)    | 1.0x (baseline)     |
| ipairs() for-loop    | 266ms | 343ms      | ~2.2x slower       | ~1.6x slower        |
| pairs() for-loop     | 268ms | 438ms      | ~2.2x slower       | ~2.1x slower        |
| next() while-loop    | 365ms | 627ms      | ~3.1x slower       | ~3.0x slower        |

Key findings:

- **Index-based `for i = 1, #tbl`** is the fastest by a clear margin.
- **`ipairs` and `pairs`** carry iterator-call overhead. On Mac they are roughly equivalent; on Steam Deck `ipairs` is noticeably faster than `pairs`.
- **`next()` while-loop** is the **slowest** of all four. Despite having no iterator protocol, the repeated `next()` calls are more expensive in practice than `ipairs`/`pairs` on this table size.
- **Rule:** Use index-based for-loops for arrays in hot paths. For hash tables requiring iteration, `pairs()` is the clearest option and performs no worse than `next()` while-loop.

### Table Insertion

Results for appending to a ~1,000-element table (reset via `setup_each` before each op):

| Method         | Mac   | Steam Deck | Mac ratio vs counter | Deck ratio vs counter |
| -------------- | ----- | ---------- | -------------------- | --------------------- |
| tbl[counter]   | 303ms | 502ms      | 1.0x (baseline)      | 1.0x (baseline)       |
| tbl[#tbl + 1]  | 375ms | 564ms      | ~1.2x slower         | ~1.1x slower          |
| table.insert() | 428ms | 639ms      | ~1.4x slower         | ~1.3x slower          |

Key findings:

- **`tbl[counter] = v; counter = counter + 1`** remains the fastest.
- **`tbl[#tbl + 1] = v`** is only ~1.1–1.2x slower when the table stays at a fixed small size (~1,000 elements). The `#` operator's cost is bounded when the table does not grow unboundedly.
- **`table.insert(tbl, v)`** (cached locally) is ~1.3–1.4x slower than the manual counter.
- **Rule:** In hot paths, use a manual counter for appending. The gap is modest at small table sizes, but the manual counter remains the safest choice for performance-critical code.
