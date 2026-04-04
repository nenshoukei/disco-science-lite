# Benchmark: Basic Lua Operations

Empirical benchmark results for basic Lua operations in the Factorio runtime environment (Lua 5.2.1).

## Method

Each test case runs N iterations, repeated for ROUNDS=3 rounds, with N\*2 warm-up iterations before timing.
The [LuaProfiler](https://lua-api.factorio.com/latest/classes/LuaProfiler.html) measures total time across all rounds, then `profiler.divide(ROUNDS)` is used to get the average per round.
The `Duration` shown in results is this average-per-round value (time for N operations).

Source: [scripts/runtime/command/ds-bench.lua](../scripts/runtime/command/ds-bench.lua)

## Test Cases

| Category     | Name                 | Code                                                                            |         N |
| ------------ | -------------------- | ------------------------------------------------------------------------------- | --------: |
| division     | 1 / pi               | `local _ = 1 / pi`                                                              | 5,000,000 |
| division     | 1 \* inv_pi          | `local _ = 1 * inv_pi` (pre-computed `inv_pi = 1 / pi`)                         | 5,000,000 |
| floor        | math.floor(n)        | `local _ = math.floor(n)`                                                       | 5,000,000 |
| floor        | n = n - n % 1        | `local _ = n - n % 1`                                                           | 5,000,000 |
| abs          | math.abs(n)          | `local _ = math.abs(n)`                                                         | 5,000,000 |
| abs          | n < 0 and -n or n    | `local _ = n < 0 and -n or n`                                                   | 5,000,000 |
| max          | math.max(n, m)       | `local _ = math.max(n, m)`                                                      | 5,000,000 |
| max          | n > m and n or m     | `local _ = n > m and n or m`                                                    | 5,000,000 |
| min          | math.min(n, m)       | `local _ = math.min(n, m)`                                                      | 5,000,000 |
| min          | n < m and n or m     | `local _ = n < m and n or m`                                                    | 5,000,000 |
| var          | Upvalue              | `local _ = upvalue + upvalue + upvalue`                                         | 5,000,000 |
| var          | Local variable       | `local lv = upvalue; local _ = lv + lv + lv`                                    | 5,000,000 |
| table:const  | Hash-key Access      | `local _ = h_table["testkey1"] + h_table["testkey50"] + h_table["testkey100"]`  | 5,000,000 |
| table:const  | Array-index Access   | `local _ = a_table[1] + a_table[50] + a_table[100]`                             | 5,000,000 |
| table:random | Hash-key Access      | `local k = h_keys[rng(N)]; local _ = h_table[k]`                                | 1,000,000 |
| table:random | Array-index Access   | `local k = a_keys[rng(N)]; local _ = a_table[k]`                                | 1,000,000 |
| loop:h_table | pairs() for-loop     | `for k, v in pairs(tbl) do end` (hash table)                                    |   100,000 |
| loop:h_table | next() while-loop    | `local k, v = next(tbl, nil); while k do k, v = next(tbl, k) end` (hash table)  |   100,000 |
| loop:a_table | pairs() for-loop     | `for k, v in pairs(tbl) do end` (array table)                                   |   100,000 |
| loop:a_table | ipairs() for-loop    | `for k, v in ipairs(tbl) do end`                                                |   100,000 |
| loop:a_table | next() while-loop    | `local k, v = next(tbl, nil); while k do k, v = next(tbl, k) end` (array table) |   100,000 |
| loop:a_table | Index-based for-loop | `for i = 1, #tbl do local _v = tbl[i] end`                                      |   100,000 |
| insert       | table.insert()       | `table.insert(tbl, v)`                                                          | 5,000,000 |
| insert       | tbl[#tbl + 1]        | `tbl[#tbl + 1] = v`                                                             | 5,000,000 |
| insert       | tbl[counter]         | `tbl[counter] = v; counter = counter + 1`                                       | 5,000,000 |

Notes:

- Factorio uses standard Lua 5.2.1 (not LuaJIT), so dead code elimination does not occur.
- Insert tests use a table pre-filled with 1,000 elements; `setup_each` resets the table to 1,000 elements before each op, so the table stays at ~1,001 elements throughout.
- Methods like `math.floor` or `table.insert` are precached as local variables.
- table:random uses a seeded [LuaRandomGenerator](https://lua-api.factorio.com/latest/classes/LuaRandomGenerator.html) reset before each round to ensure identical access patterns across rounds.
- For each category, `N` is tuned so that each test run is neither too short to measure accurately nor too long to complete in reasonable time.

## Results

The `Average Duration` column is the Factorio profiler output: average time per round (covering N operations).

### Mac

Mac Studio + Apple M2 Max + 32GB RAM

| Category     | Name                 |       Duration |
| ------------ | -------------------- | -------------: |
| division     | 1 / pi               | `102.961834ms` |
| division     | 1 \* inv_pi          | `104.115070ms` |
| floor        | math.floor(n)        | `157.211431ms` |
| floor        | n = n - n % 1        | `122.495153ms` |
| abs          | math.abs(n)          | `157.419694ms` |
| abs          | n < 0 and -n or n    | `134.212584ms` |
| max          | math.max(n, m)       | `179.442139ms` |
| max          | n > m and n or m     | `117.093431ms` |
| min          | math.min(n, m)       | `179.551930ms` |
| min          | n < m and n or m     | `130.552431ms` |
| var          | Upvalue              | `125.212778ms` |
| var          | Local variable       | `110.792264ms` |
| table:const  | Hash-key Access      | `174.858695ms` |
| table:const  | Array-index Access   | `246.578278ms` |
| table:random | Hash-key Access      | `118.138777ms` |
| table:random | Array-index Access   | `119.522264ms` |
| loop:h_table | pairs() for-loop     | `273.725778ms` |
| loop:h_table | next() while-loop    | `369.691819ms` |
| loop:a_table | pairs() for-loop     | `204.229820ms` |
| loop:a_table | ipairs() for-loop    | `260.026167ms` |
| loop:a_table | next() while-loop    | `326.070667ms` |
| loop:a_table | Index-based for-loop | `120.520528ms` |
| insert       | table.insert()       | `416.595222ms` |
| insert       | tbl[#tbl + 1]        | `372.056847ms` |
| insert       | tbl[counter]         | `302.400722ms` |

<details>
<summary>Raw format</summary>

```
### Benchmark results
| Category     | Name                 | Average                | Round 1                | Round 2                | Round 3                |
| ------------ | -------------------- | ---------------------- | ---------------------- | ---------------------- | ---------------------- |
| division     | 1 / pi               | Duration: 102.961834ms | Duration: 103.094875ms | Duration: 102.925084ms | Duration: 102.865542ms |
| division     | 1 * inv_pi           | Duration: 104.115070ms | Duration: 104.033042ms | Duration: 104.390750ms | Duration: 103.921417ms |
| floor        | math.floor(n)        | Duration: 157.211431ms | Duration: 157.128125ms | Duration: 157.233667ms | Duration: 157.272500ms |
| floor        | n = n - n % 1        | Duration: 122.495153ms | Duration: 122.318792ms | Duration: 122.262000ms | Duration: 122.904667ms |
| abs          | math.abs(n)          | Duration: 157.419694ms | Duration: 157.512292ms | Duration: 157.221541ms | Duration: 157.525250ms |
| abs          | n < 0 and -n or n    | Duration: 134.212584ms | Duration: 134.294542ms | Duration: 133.884042ms | Duration: 134.459167ms |
| max          | math.max(n, m)       | Duration: 179.442139ms | Duration: 178.757083ms | Duration: 179.658167ms | Duration: 179.911167ms |
| max          | n > m and n or m     | Duration: 117.093431ms | Duration: 117.235375ms | Duration: 116.914875ms | Duration: 117.130042ms |
| min          | math.min(n, m)       | Duration: 179.551930ms | Duration: 179.280333ms | Duration: 179.719625ms | Duration: 179.655833ms |
| min          | n < m and n or m     | Duration: 130.552431ms | Duration: 130.467875ms | Duration: 130.681792ms | Duration: 130.507625ms |
| var          | Upvalue              | Duration: 125.212778ms | Duration: 125.051167ms | Duration: 125.407083ms | Duration: 125.180083ms |
| var          | Local variable       | Duration: 110.792264ms | Duration: 110.793291ms | Duration: 110.742000ms | Duration: 110.841500ms |
| table:const  | Hash-key Access      | Duration: 174.858695ms | Duration: 174.984750ms | Duration: 174.853792ms | Duration: 174.737542ms |
| table:const  | Array-index Access   | Duration: 246.578278ms | Duration: 247.470333ms | Duration: 244.907417ms | Duration: 247.357083ms |
| table:random | Hash-key Access      | Duration: 118.138777ms | Duration: 118.197291ms | Duration: 118.253958ms | Duration: 117.965083ms |
| table:random | Array-index Access   | Duration: 119.522264ms | Duration: 119.422792ms | Duration: 119.653875ms | Duration: 119.490125ms |
| loop:h_table | pairs() for-loop     | Duration: 273.725778ms | Duration: 274.096708ms | Duration: 273.767000ms | Duration: 273.313625ms |
| loop:h_table | next() while-loop    | Duration: 369.691819ms | Duration: 369.913292ms | Duration: 369.068208ms | Duration: 370.093958ms |
| loop:a_table | pairs() for-loop     | Duration: 204.229820ms | Duration: 204.248458ms | Duration: 204.431209ms | Duration: 204.009792ms |
| loop:a_table | ipairs() for-loop    | Duration: 260.026167ms | Duration: 260.519542ms | Duration: 260.081875ms | Duration: 259.477083ms |
| loop:a_table | next() while-loop    | Duration: 326.070667ms | Duration: 326.166708ms | Duration: 326.115375ms | Duration: 325.929917ms |
| loop:a_table | Index-based for-loop | Duration: 120.520528ms | Duration: 120.416000ms | Duration: 120.907500ms | Duration: 120.238084ms |
| insert       | table.insert()       | Duration: 416.595222ms | Duration: 416.160417ms | Duration: 416.620250ms | Duration: 417.005000ms |
| insert       | tbl[#tbl + 1]        | Duration: 372.056847ms | Duration: 372.756083ms | Duration: 371.514041ms | Duration: 371.900417ms |
| insert       | tbl[counter]         | Duration: 302.400722ms | Duration: 302.515250ms | Duration: 301.933375ms | Duration: 302.753541ms |
```

</details>

### Steam Deck

Steam Deck LCD + AMD APU 3.5GHz + 16GB RAM

| Category     | Name                 |       Duration |
| ------------ | -------------------- | -------------: |
| division     | 1 / pi               | `169.998339ms` |
| division     | 1 \* inv_pi          | `148.514008ms` |
| floor        | math.floor(n)        | `244.862526ms` |
| floor        | n = n - n % 1        | `190.605010ms` |
| abs          | math.abs(n)          | `232.226934ms` |
| abs          | n < 0 and -n or n    | `207.298029ms` |
| max          | math.max(n, m)       | `263.417394ms` |
| max          | n > m and n or m     | `182.234961ms` |
| min          | math.min(n, m)       | `263.992299ms` |
| min          | n < m and n or m     | `198.712169ms` |
| var          | Upvalue              | `177.751111ms` |
| var          | Local variable       | `163.659672ms` |
| table:const  | Hash-key Access      | `311.978026ms` |
| table:const  | Array-index Access   | `566.839386ms` |
| table:random | Hash-key Access      | `132.697907ms` |
| table:random | Array-index Access   | `138.169083ms` |
| loop:h_table | pairs() for-loop     | `476.237645ms` |
| loop:h_table | next() while-loop    | `600.200026ms` |
| loop:a_table | pairs() for-loop     | `332.331342ms` |
| loop:a_table | ipairs() for-loop    | `380.413265ms` |
| loop:a_table | next() while-loop    | `460.815662ms` |
| loop:a_table | Index-based for-loop | `217.166592ms` |
| insert       | table.insert()       | `643.481559ms` |
| insert       | tbl[#tbl + 1]        | `564.339821ms` |
| insert       | tbl[counter]         | `502.404820ms` |

<details>
<summary>Raw format</summary>

```
### Benchmark results
| Category     | Name                 | Average                | Round 1                | Round 2                | Round 3                |
| ------------ | -------------------- | ---------------------- | ---------------------- | ---------------------- | ---------------------- |
| division     | 1 / pi               | Duration: 169.998339ms | Duration: 191.146258ms | Duration: 167.801062ms | Duration: 151.047698ms |
| division     | 1 * inv_pi           | Duration: 148.514008ms | Duration: 147.738702ms | Duration: 149.252657ms | Duration: 148.550665ms |
| floor        | math.floor(n)        | Duration: 244.862526ms | Duration: 242.810478ms | Duration: 243.707207ms | Duration: 248.069892ms |
| floor        | n = n - n % 1        | Duration: 190.605010ms | Duration: 188.959321ms | Duration: 191.680392ms | Duration: 191.175318ms |
| abs          | math.abs(n)          | Duration: 232.226934ms | Duration: 233.135878ms | Duration: 232.246327ms | Duration: 231.298598ms |
| abs          | n < 0 and -n or n    | Duration: 207.298029ms | Duration: 203.924064ms | Duration: 209.079620ms | Duration: 208.890403ms |
| max          | math.max(n, m)       | Duration: 263.417394ms | Duration: 261.684499ms | Duration: 263.558149ms | Duration: 265.009535ms |
| max          | n > m and n or m     | Duration: 182.234961ms | Duration: 181.063614ms | Duration: 183.089392ms | Duration: 182.551878ms |
| min          | math.min(n, m)       | Duration: 263.992299ms | Duration: 264.732098ms | Duration: 263.449171ms | Duration: 263.795627ms |
| min          | n < m and n or m     | Duration: 198.712169ms | Duration: 199.032966ms | Duration: 198.787458ms | Duration: 198.316083ms |
| var          | Upvalue              | Duration: 177.751111ms | Duration: 176.640710ms | Duration: 175.110915ms | Duration: 181.501709ms |
| var          | Local variable       | Duration: 163.659672ms | Duration: 158.954375ms | Duration: 164.216069ms | Duration: 167.808572ms |
| table:const  | Hash-key Access      | Duration: 311.978026ms | Duration: 312.637306ms | Duration: 312.268059ms | Duration: 311.028712ms |
| table:const  | Array-index Access   | Duration: 566.839386ms | Duration: 567.720963ms | Duration: 566.845223ms | Duration: 565.951972ms |
| table:random | Hash-key Access      | Duration: 132.697907ms | Duration: 132.603221ms | Duration: 132.750890ms | Duration: 132.739610ms |
| table:random | Array-index Access   | Duration: 138.169083ms | Duration: 137.498119ms | Duration: 140.677227ms | Duration: 136.331902ms |
| loop:h_table | pairs() for-loop     | Duration: 476.237645ms | Duration: 476.279911ms | Duration: 476.329430ms | Duration: 476.103593ms |
| loop:h_table | next() while-loop    | Duration: 600.200026ms | Duration: 600.600479ms | Duration: 601.967885ms | Duration: 598.031715ms |
| loop:a_table | pairs() for-loop     | Duration: 332.331342ms | Duration: 332.232330ms | Duration: 332.188280ms | Duration: 332.573416ms |
| loop:a_table | ipairs() for-loop    | Duration: 380.413265ms | Duration: 379.045099ms | Duration: 380.853740ms | Duration: 381.340956ms |
| loop:a_table | next() while-loop    | Duration: 460.815662ms | Duration: 477.978823ms | Duration: 454.870714ms | Duration: 449.597450ms |
| loop:a_table | Index-based for-loop | Duration: 217.166592ms | Duration: 218.355402ms | Duration: 217.284144ms | Duration: 215.860229ms |
| insert       | table.insert()       | Duration: 643.481559ms | Duration: 645.521128ms | Duration: 640.865066ms | Duration: 644.058483ms |
| insert       | tbl[#tbl + 1]        | Duration: 564.339821ms | Duration: 575.807767ms | Duration: 557.437491ms | Duration: 559.774205ms |
| insert       | tbl[counter]         | Duration: 502.404820ms | Duration: 502.184598ms | Duration: 500.926453ms | Duration: 504.103409ms |
```

</details>

## Conclusions

### Arithmetic Operations

**Division vs. Multiplication:** On Mac, no meaningful difference. On Steam Deck, pre-computing `inv_pi` gives a ~1.1x speedup, suggesting the division penalty is more pronounced on lower-power hardware.

### Standard Library vs. Inline Logic

Calling standard library functions has overhead compared to equivalent inline logic.

| Operation      | Standard Library | Inline Equivalent   | Mac ratio | Steam Deck ratio |
| -------------- | ---------------- | ------------------- | --------- | ---------------- |
| Integer Floor  | `math.floor(n)`  | `n - n % 1`         | ~1.28x    | ~1.30x           |
| Absolute Value | `math.abs(n)`    | `n < 0 and -n or n` | ~1.2x     | ~1.1x            |
| Maximum        | `math.max(n, m)` | `n > m and n or m`  | ~1.5x     | ~1.4x            |
| Minimum        | `math.min(n, m)` | `n < m and n or m`  | ~1.4x     | ~1.3x            |

**Rule:** In hot paths, prefer inline conditional logic over `math.*` functions for floor/abs/max/min.

### Hash-key Access vs. Array-index Access

Results differ significantly between access patterns:

**Constant-index access** (same fixed keys every iteration):

| Platform   | Hash-key | Array-index | Ratio (array/hash) |
| ---------- | -------- | ----------- | ------------------ |
| Mac        | 174ms    | 246ms       | ~1.4x slower       |
| Steam Deck | 311ms    | 566ms       | ~1.8x slower       |

**Random-index access** (key chosen by RNG each iteration):

| Platform   | Hash-key | Array-index | Ratio        |
| ---------- | -------- | ----------- | ------------ |
| Mac        | 118ms    | 119ms       | ~1.0x (same) |
| Steam Deck | 132ms    | 138ms       | ~1.0x (same) |

**Key finding:** The hash-key advantage disappears entirely with random access. The gap in constant-index access is likely a cache or branch-prediction effect from the VM resolving the same slot repeatedly. With random keys, both access methods are equivalent.

**Rule:** When repeatedly accessing the same fixed keys in a hot path, hash-key access is faster. For general random access, there is no meaningful difference.

### Upvalue vs. Local Variable

Local variables are marginally faster (~1.1–1.13x) than upvalues. The difference is small but consistent.

### For-loop Iteration

**Hash table** (100-element hash table, N=100,000 full iterations):

| Method            | Mac   | Steam Deck | Mac ratio vs pairs | Deck ratio vs pairs |
| ----------------- | ----- | ---------- | ------------------ | ------------------- |
| pairs() for-loop  | 273ms | 476ms      | 1.0x (baseline)    | 1.0x (baseline)     |
| next() while-loop | 369ms | 600ms      | ~1.3x slower       | ~1.3x slower        |

`pairs()` is faster than `next()` while-loop for hash tables on both platforms.

**Array table** (100-element array table, N=100,000 full iterations):

| Method               | Mac   | Steam Deck | Mac ratio vs index | Deck ratio vs index |
| -------------------- | ----- | ---------- | ------------------ | ------------------- |
| Index-based for-loop | 120ms | 217ms      | 1.0x (baseline)    | 1.0x (baseline)     |
| pairs() for-loop     | 204ms | 332ms      | ~1.7x slower       | ~1.5x slower        |
| ipairs() for-loop    | 260ms | 380ms      | ~2.2x slower       | ~1.8x slower        |
| next() while-loop    | 326ms | 461ms      | ~2.7x slower       | ~2.1x slower        |

Key findings:

- **Index-based `for i = 1, #tbl`** is the fastest for arrays by a clear margin.
- **`pairs()`** is faster than `ipairs()` for array iteration on both platforms (~1.3–1.5x vs ~1.8–2.2x slower than index-based).
- **`next()` while-loop** is the **slowest** for both hash and array tables. Despite having no iterator protocol, the repeated `next()` calls are more expensive in practice.
- **Rule:** Use index-based for-loops for arrays in hot paths. For hash tables, `pairs()` is both the clearest and fastest option.

### Table Insertion

Results for appending to a ~1,000-element table (reset via `setup_each` before each op):

| Method         | Mac   | Steam Deck | Mac ratio vs counter | Deck ratio vs counter |
| -------------- | ----- | ---------- | -------------------- | --------------------- |
| tbl[counter]   | 302ms | 502ms      | 1.0x (baseline)      | 1.0x (baseline)       |
| tbl[#tbl + 1]  | 372ms | 564ms      | ~1.2x slower         | ~1.1x slower          |
| table.insert() | 416ms | 643ms      | ~1.4x slower         | ~1.3x slower          |

Key findings:

- **`tbl[counter] = v; counter = counter + 1`** remains the fastest.
- **`tbl[#tbl + 1] = v`** is only ~1.1–1.2x slower when the table stays at a fixed small size (~1,000 elements). The `#` operator's cost is bounded when the table does not grow unboundedly.
- **`table.insert(tbl, v)`** is ~1.3–1.4x slower than the manual counter.
- **Rule:** In hot paths, use a manual counter for appending. The gap is modest at small table sizes, but the manual counter remains the safest choice for performance-critical code.
