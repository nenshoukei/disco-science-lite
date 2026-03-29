# Benchmark: Basic Lua Operations

Empirical benchmark results for basic Lua operations in the Factorio runtime environment (Lua 5.2.1) on Mac with Apple M2 Max + 32GB RAM.

## Method

Each test case runs N=100,000 iterations, repeated for ROUNDS=10 rounds, with N warm-up iterations before timing.
The profiler measures total time across all rounds, then `profiler.divide(ROUNDS)` is used to get the average per round.

Source: [scripts/runtime/command/ds-bench.lua](../scripts/runtime/command/ds-bench.lua)

## Test Cases

| Name                          | Code                                                               |
| ----------------------------- | ------------------------------------------------------------------ |
| math: 1 / pi                  | `local _ = 1 / pi`                                                 |
| math: 1 \* inv_pi             | `local _ = 1 * inv_pi` (pre-computed `inv_pi = 1 / pi`)            |
| math: math.floor(n)           | `local _ = math.floor(n)`                                          |
| math: n = n - n % 1           | `local _ = n - n % 1`                                              |
| math: math.floor(n / 32)      | `local _ = math.floor(n / 32)`                                     |
| math: n = n / 32; n = n - n%1 | `local _ = n / 32; _ = _ - _ % 1`                                  |
| math: bit32.rshift(n, 5)      | `local _ = bit32.rshift(n, 5)`                                     |
| math: math.abs(n)             | `local _ = math.abs(n)`                                            |
| math: n < 0 and -n or n       | `local _ = n < 0 and -n or n`                                      |
| math: math.max(n, m)          | `local _ = math.max(n, m)`                                         |
| math: n > m and n or m        | `local _ = n > m and n or m`                                       |
| math: math.min(n, m)          | `local _ = math.min(n, m)`                                         |
| math: n < m and n or m        | `local _ = n < m and n or m`                                       |
| table: Hash-key Access        | `local _ = h_table.x + h_table.y + h_table.z`                      |
| table: Array-index Access     | `local _ = a_table[1] + a_table[2] + a_table[3]`                   |
| var: Upvalue                  | `local _ = upvalue + upvalue`                                      |
| var: Local variable           | `local lv = upvalue; local _ = lv + lv`                            |
| loop: Index-based for-loop    | `for i = 1, #tbl do local _v = tbl[i] end`                         |
| loop: ipairs() for-loop       | `for k, v in ipairs(tbl) do end`                                   |
| loop: pairs() for-loop        | `for k, v in pairs(tbl) do end`                                    |
| loop: next() while-loop       | `local k, v = next(tbl, nil); while k do k, v = next(tbl, k) end`  |
| insert: table.insert()        | `table_insert(tbl, v)` (where `local table_insert = table.insert`) |
| insert: tbl[#tbl + 1]         | `tbl[#tbl + 1] = v`                                                |
| insert: tbl[counter]          | `tbl[counter] = v; counter = counter + 1`                          |

Note: Factorio uses standard Lua 5.2.1 (not LuaJIT), so dead code elimination does not occur.

## Results

Results show the average duration per round (N=100,000 ops), per-op time, and throughput.

- `ops/tick` is calculated based on the ideal Factorio simulation speed of 60 ticks per second (1 tick = 16.67ms).
- one "op" for loop cases = one complete iteration over a 3-element table.
- Absolute times vary ~5% between runs due to OS CPU scheduling.

### Run 1

```
--- Benchmarking 24 cases (N=100000, ROUNDS=10) ---
math: 1 / pi                  : Total  481.67 ms, Avg 0.004816 ms;  207.6126 ops/ms, 3460.2102 ops/tick
math: 1 * inv_pi              : Total  464.06 ms, Avg 0.004640 ms;  215.4874 ops/ms, 3591.4574 ops/tick
math: math.floor(n)           : Total  930.08 ms, Avg 0.009300 ms;  107.5179 ops/ms, 1791.9646 ops/tick
math: n = n - n % 1           : Total  473.55 ms, Avg 0.004735 ms;  211.1725 ops/ms, 3519.5411 ops/tick
math: math.floor(n / 32)      : Total  926.16 ms, Avg 0.009261 ms;  107.9729 ops/ms, 1799.5487 ops/tick
math: n = n / 32; n = n - n%1 : Total  472.63 ms, Avg 0.004726 ms;  211.5808 ops/ms, 3526.3467 ops/tick
math: bit32.rshift(n, 5)      : Total  917.65 ms, Avg 0.009176 ms;  108.9745 ops/ms, 1816.2421 ops/tick
math: math.abs(n)             : Total  931.81 ms, Avg 0.009318 ms;  107.3184 ops/ms, 1788.6404 ops/tick
math: n < 0 and -n or n       : Total  458.72 ms, Avg 0.004587 ms;  217.9992 ops/ms, 3633.3195 ops/tick
math: math.max(n, m)          : Total  938.32 ms, Avg 0.009383 ms;  106.5740 ops/ms, 1776.2335 ops/tick
math: n > m and n or m        : Total  464.96 ms, Avg 0.004649 ms;  215.0739 ops/ms, 3584.5657 ops/tick
math: math.min(n, m)          : Total  948.67 ms, Avg 0.009486 ms;  105.4108 ops/ms, 1756.8470 ops/tick
math: n < m and n or m        : Total  465.80 ms, Avg 0.004658 ms;  214.6839 ops/ms, 3578.0643 ops/tick
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
--- Benchmarking 24 cases (N=100000, ROUNDS=10) ---
math: 1 / pi                  : Total  501.46 ms, Avg 0.005014 ms;  199.4187 ops/ms, 3323.6444 ops/tick
math: 1 * inv_pi              : Total  471.71 ms, Avg 0.004717 ms;  211.9934 ops/ms, 3533.2236 ops/tick
math: math.floor(n)           : Total  932.10 ms, Avg 0.009321 ms;  107.2841 ops/ms, 1788.0688 ops/tick
math: n = n - n % 1           : Total  467.80 ms, Avg 0.004678 ms;  213.7658 ops/ms, 3562.7638 ops/tick
math: math.floor(n / 32)      : Total  934.57 ms, Avg 0.009345 ms;  107.0010 ops/ms, 1783.3493 ops/tick
math: n = n / 32; n = n - n%1 : Total  468.94 ms, Avg 0.004689 ms;  213.2449 ops/ms, 3554.0820 ops/tick
math: bit32.rshift(n, 5)      : Total  942.67 ms, Avg 0.009426 ms;  106.0819 ops/ms, 1768.0313 ops/tick
math: math.abs(n)             : Total  901.69 ms, Avg 0.009016 ms;  110.9033 ops/ms, 1848.3886 ops/tick
math: n < 0 and -n or n       : Total  497.61 ms, Avg 0.004976 ms;  200.9595 ops/ms, 3349.3251 ops/tick
math: math.max(n, m)          : Total  907.20 ms, Avg 0.009072 ms;  110.2290 ops/ms, 1837.1508 ops/tick
math: n > m and n or m        : Total  495.37 ms, Avg 0.004953 ms;  201.8681 ops/ms, 3364.4691 ops/tick
math: math.min(n, m)          : Total  909.81 ms, Avg 0.009098 ms;  109.9125 ops/ms, 1831.8751 ops/tick
math: n < m and n or m        : Total  491.00 ms, Avg 0.004909 ms;  203.6664 ops/ms, 3394.4407 ops/tick
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
--- Benchmarking 24 cases (N=100000, ROUNDS=10) ---
math: 1 / pi                  : Total  476.52 ms, Avg 0.004765 ms;  209.8527 ops/ms, 3497.5448 ops/tick
math: 1 * inv_pi              : Total  493.11 ms, Avg 0.004931 ms;  202.7959 ops/ms, 3379.9312 ops/tick
math: math.floor(n)           : Total  978.05 ms, Avg 0.009780 ms;  102.2443 ops/ms, 1704.0714 ops/tick
math: n = n - n % 1           : Total  508.17 ms, Avg 0.005081 ms;  196.7849 ops/ms, 3279.7481 ops/tick
math: math.floor(n / 32)      : Total  976.92 ms, Avg 0.009769 ms;  102.3623 ops/ms, 1706.0380 ops/tick
math: n = n / 32; n = n - n%1 : Total  509.26 ms, Avg 0.005092 ms;  196.3628 ops/ms, 3272.7141 ops/tick
math: bit32.rshift(n, 5)      : Total  979.57 ms, Avg 0.009795 ms;  102.0853 ops/ms, 1701.4214 ops/tick
math: math.abs(n)             : Total  975.77 ms, Avg 0.009757 ms;  102.4834 ops/ms, 1708.0567 ops/tick
math: n < 0 and -n or n       : Total  512.64 ms, Avg 0.005126 ms;  195.0679 ops/ms, 3251.1322 ops/tick
math: math.max(n, m)          : Total  975.77 ms, Avg 0.009757 ms;  102.4831 ops/ms, 1708.0518 ops/tick
math: n > m and n or m        : Total  511.61 ms, Avg 0.005116 ms;  195.4623 ops/ms, 3257.7050 ops/tick
math: math.min(n, m)          : Total  975.81 ms, Avg 0.009758 ms;  102.4792 ops/ms, 1707.9867 ops/tick
math: n < m and n or m        : Total  512.72 ms, Avg 0.005127 ms;  195.0397 ops/ms, 3250.6620 ops/tick
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

### Arithmetic Operations (Division, Multiplication, and Integers)

- **Multiplication vs. Division:** No meaningful performance difference (~480ms range) for basic floating point operations.
- **Integer Floor:** `n - n % 1` is **~2x faster** than `math.floor(n)`.
- **Bitwise Shifts:** For powers of 2, `n/32 - (n/32)%1` is **~2x faster** than `bit32.rshift(n, 5)`, which is as slow as `math.floor`.

### Standard Library vs. Inline Logic

In the Factorio Lua environment (5.2.1), calling standard library functions has significant overhead compared to equivalent inline logic.

| Operation      | Standard Library          | Inline Equivalent            | Ratio |
| -------------- | ------------------------- | ---------------------------- | ----- |
| Absolute Value | `math.abs(n)` (~930ms)    | `n < 0 and -n or n` (~460ms) | ~2.0x |
| Maximum        | `math.max(n, m)` (~940ms) | `n > m and n or m` (~460ms)  | ~2.0x |
| Minimum        | `math.min(n, m)` (~950ms) | `n < m and n or m` (~460ms)  | ~2.1x |

**Rule:** In hot paths, **avoid `math.*` and `bit32.*`** if the same result can be achieved with simple conditional logic or arithmetic.

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
