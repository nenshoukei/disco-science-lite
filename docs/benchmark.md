# Benchmark: Basic Lua Operations

Empirical benchmark results for basic Lua operations in the Factorio runtime environment (Lua 5.2.1) on Mac with Apple M2 Max + 32GB RAM.

## Method

Each test case runs N=100,000 iterations, repeated for ROUNDS=10 rounds, with N warm-up iterations before timing.
The profiler measures total time across all rounds, then `profiler.divide(ROUNDS)` is used to get the average per round.

Source: [scripts/runtime/control/benchmark.lua](../scripts/runtime/control/benchmark.lua)

## Test Cases

| Name                       | Code                                                               |
| -------------------------- | ------------------------------------------------------------------ |
| math: Division             | `local _ = 1 / pi`                                                 |
| math: Multiplication       | `local _ = 1 * inv_pi` (pre-computed `inv_pi = 1 / pi`)            |
| table: Hash-key Access     | `local _ = h_table.x + h_table.y + h_table.z`                      |
| table: Array-index Access  | `local _ = a_table[1] + a_table[2] + a_table[3]`                   |
| var: Upvalue               | `local _ = upvalue + upvalue`                                      |
| var: Local variable        | `local lv = upvalue; local _ = lv + lv`                            |
| loop: Index-based for-loop | `for i = 1, #tbl do local _v = tbl[i] end`                         |
| loop: ipairs() for-loop    | `for k, v in ipairs(tbl) do end`                                   |
| loop: pairs() for-loop     | `for k, v in pairs(tbl) do end`                                    |
| loop: next() while-loop    | `local k, v = next(tbl, nil); while k do k, v = next(tbl, k) end`  |
| insert: table.insert()     | `table_insert(tbl, v)` (where `local table_insert = table.insert`) |
| insert: tbl[#tbl + 1]      | `tbl[#tbl + 1] = v`                                                |
| insert: tbl[counter]       | `tbl[counter] = v; counter = counter + 1`                          |

Note: Factorio uses standard Lua 5.2.1 (not LuaJIT), so dead code elimination does not occur.

## Results

Results show the average duration per round (N=100,000 ops), per-op time, and throughput.

- `ops/tick` is calculated based on the ideal Factorio simulation speed of 60 ticks per second (1 tick = 16.67ms).
- one "op" for loop cases = one complete iteration over a 3-element table.
- Absolute times vary ~5% between runs due to OS CPU scheduling.

### Run 1

```
--- Benchmarking 13 cases (N=100000, ROUNDS=10) ---
math: Division                : Total  491.45 ms, Avg 0.004914 ms;  203.4788 ops/ms, 3391.3125 ops/tick
math: Multiplication          : Total  461.29 ms, Avg 0.004612 ms;  216.7822 ops/ms, 3613.0373 ops/tick
table: Hash-key Access        : Total  510.80 ms, Avg 0.005107 ms;  195.7723 ops/ms, 3262.8721 ops/tick
table: Array-index Access     : Total  480.56 ms, Avg 0.004805 ms;  208.0910 ops/ms, 3468.1827 ops/tick
var: Upvalue                  : Total  475.33 ms, Avg 0.004753 ms;  210.3794 ops/ms, 3506.3236 ops/tick
var: Local variable           : Total  508.26 ms, Avg 0.005082 ms;  196.7494 ops/ms, 3279.1562 ops/tick
loop: Index-based for-loop    : Total  473.24 ms, Avg 0.004732 ms;  211.3102 ops/ms, 3521.8372 ops/tick
loop: ipairs() for-loop       : Total 2677.16 ms, Avg 0.026771 ms;   37.3530 ops/ms,  622.5493 ops/tick
loop: pairs() for-loop        : Total 2687.10 ms, Avg 0.026871 ms;   37.2148 ops/ms,  620.2466 ops/tick
loop: next() while-loop       : Total 2255.95 ms, Avg 0.022559 ms;   44.3271 ops/ms,  738.7857 ops/tick
insert: table.insert()        : Total 1191.08 ms, Avg 0.011910 ms;   83.9571 ops/ms, 1399.2850 ops/tick
insert: tbl[#tbl + 1]         : Total 2636.26 ms, Avg 0.026362 ms;   37.9325 ops/ms,  632.2086 ops/tick
insert: tbl[counter]          : Total  536.62 ms, Avg 0.005366 ms;  186.3510 ops/ms, 3105.8504 ops/tick
```

### Run 2

```
--- Benchmarking 13 cases (N=100000, ROUNDS=10) ---
math: Division                : Total  473.74 ms, Avg 0.004737 ms;  211.0848 ops/ms, 3518.0793 ops/tick
math: Multiplication          : Total  502.44 ms, Avg 0.005024 ms;  199.0305 ops/ms, 3317.1745 ops/tick
table: Hash-key Access        : Total  498.75 ms, Avg 0.004987 ms;  200.5002 ops/ms, 3341.6702 ops/tick
table: Array-index Access     : Total  481.23 ms, Avg 0.004812 ms;  207.8026 ops/ms, 3463.3774 ops/tick
var: Upvalue                  : Total  511.41 ms, Avg 0.005114 ms;  195.5373 ops/ms, 3258.9546 ops/tick
var: Local variable           : Total  481.74 ms, Avg 0.004817 ms;  207.5796 ops/ms, 3459.6598 ops/tick
loop: Index-based for-loop    : Total  494.06 ms, Avg 0.004940 ms;  202.4054 ops/ms, 3373.4230 ops/tick
loop: ipairs() for-loop       : Total 2663.46 ms, Avg 0.026634 ms;   37.5451 ops/ms,  625.7515 ops/tick
loop: pairs() for-loop        : Total 2667.15 ms, Avg 0.026671 ms;   37.4932 ops/ms,  624.8863 ops/tick
loop: next() while-loop       : Total 2260.23 ms, Avg 0.022602 ms;   44.2433 ops/ms,  737.3881 ops/tick
insert: table.insert()        : Total 1186.28 ms, Avg 0.011862 ms;   84.2974 ops/ms, 1404.9569 ops/tick
insert: tbl[#tbl + 1]         : Total 2631.27 ms, Avg 0.026312 ms;   38.0045 ops/ms,  633.4087 ops/tick
insert: tbl[counter]          : Total  536.98 ms, Avg 0.005369 ms;  186.2251 ops/ms, 3103.7519 ops/tick
```

### Run 3

```
--- Benchmarking 13 cases (N=100000, ROUNDS=10) ---
math: Division                : Total  481.99 ms, Avg 0.004819 ms;  207.4751 ops/ms, 3457.9181 ops/tick
math: Multiplication          : Total  503.96 ms, Avg 0.005039 ms;  198.4293 ops/ms, 3307.1547 ops/tick
table: Hash-key Access        : Total  469.41 ms, Avg 0.004694 ms;  213.0314 ops/ms, 3550.5234 ops/tick
table: Array-index Access     : Total  489.16 ms, Avg 0.004891 ms;  204.4326 ops/ms, 3407.2103 ops/tick
var: Upvalue                  : Total  504.67 ms, Avg 0.005046 ms;  198.1507 ops/ms, 3302.5115 ops/tick
var: Local variable           : Total  470.35 ms, Avg 0.004703 ms;  212.6091 ops/ms, 3543.4854 ops/tick
loop: Index-based for-loop    : Total  497.28 ms, Avg 0.004972 ms;  201.0923 ops/ms, 3351.5389 ops/tick
loop: ipairs() for-loop       : Total 2650.15 ms, Avg 0.026501 ms;   37.7337 ops/ms,  628.8946 ops/tick
loop: pairs() for-loop        : Total 2638.93 ms, Avg 0.026389 ms;   37.8942 ops/ms,  631.5693 ops/tick
loop: next() while-loop       : Total 2230.54 ms, Avg 0.022305 ms;   44.8323 ops/ms,  747.2047 ops/tick
insert: table.insert()        : Total 1189.04 ms, Avg 0.011890 ms;   84.1014 ops/ms, 1401.6905 ops/tick
insert: tbl[#tbl + 1]         : Total 2628.61 ms, Avg 0.026286 ms;   38.0429 ops/ms,  634.0481 ops/tick
insert: tbl[counter]          : Total  541.67 ms, Avg 0.005416 ms;  184.6137 ops/ms, 3076.8955 ops/tick
```

## Conclusions

### Multiplication vs. Division

- No meaningful performance difference (~480ms range). Choose based on readability.

### Hash-key Access vs. Array-index Access

- No meaningful performance difference (~490ms range). Choose based on readability.

### Upvalue vs. Local Variable

- No meaningful performance difference (~490ms range). Choose based on readability.

### For-loop Iteration

This is the largest and most reproducible performance gap found.
The ratios are stable across all 3 runs.

Results for iterating a 3-element table (N=100,000):

| Method               | Run 1  | Run 2  | Run 3  | Ratio vs index-based |
| -------------------- | ------ | ------ | ------ | -------------------- |
| Index-based for-loop | 473ms  | 494ms  | 497ms  | 1.0x (baseline)      |
| next() while-loop    | 2256ms | 2260ms | 2231ms | ~4.5–4.8x slower     |
| ipairs() for-loop    | 2677ms | 2663ms | 2650ms | ~5.3–5.7x slower     |
| pairs() for-loop     | 2687ms | 2667ms | 2639ms | ~5.3–5.7x slower     |

Key findings:

- **Index-based `for i = 1, #tbl`** remains the fastest, with virtually zero loop overhead.
- **`ipairs` and `pairs`** are ~5.5x slower due to the generic-for iterator call overhead.
- **`next()` while-loop** is slightly faster than `ipairs`/`pairs` by avoiding the iterator protocol.
- **Rule:** Use index-based for-loops for arrays in hot paths. For hash tables, `next()` while-loop is preferable to `pairs()` when performance matters.

### Table Insertion (Hot Path)

Results for appending to a table that grows up to 1,100,000 elements:

| Method         | Run 1  | Run 2  | Run 3  | Ratio vs tbl[counter] |
| -------------- | ------ | ------ | ------ | --------------------- |
| tbl[counter]   | 537ms  | 537ms  | 542ms  | 1.0x (baseline)       |
| table.insert() | 1191ms | 1186ms | 1189ms | ~2.2x slower          |
| tbl[#tbl + 1]  | 2636ms | 2631ms | 2629ms | ~4.9x slower          |

Key findings (Crucial Insight for large N):

- **`tbl[counter] = v; counter = counter + 1`** is the absolute winner. It avoids the $O(\log N)$ overhead of the `#` operator entirely.
- **`table.insert(tbl, v)`** (cached locally) is ~2.2x slower than using a manual counter, but ~2.2x FASTER than `#tbl + 1`.
- **`tbl[#tbl + 1] = v`** is extremely slow for large tables (~5x slower than manual counter) because the `#` operator must search for the end of the table in every iteration. At high iteration counts ($N \ge 100,000$), the cost of the `#` operator becomes the dominant bottleneck for table insertions.
- **Rule:** In hot paths (like rendering overlays every tick), **ALWAYS use a manual counter** for building tables. Avoid `#tbl` or `table.insert` if performance is critical.
