--- @diagnostic disable: unused-local, empty-block

local ROUNDS = 5
local OUT_FILE = "lua-benchmark.md" -- in `script-output/`

commands.add_command(
  "ds-bench",
  "Run Lua operation benchmark. Usage: /ds-bench [category]",
  function (event)
    local player_index = event.player_index
    if not player_index then return end
    local category_filter = event.parameter

    local pi = math.pi
    local inv_pi = 1 / pi
    local negative = -12345
    local n, m = 123, 456
    local h_table = {}; for i = 1, 100 do h_table["i" .. i] = i end
    local a_table = {}; for i = 1, 100 do a_table[i] = i end
    local upvalue = 1
    local test_table = {}
    local test_counter = 0
    local table_insert = table.insert
    local floor = math.floor
    local abs = math.abs
    local max = math.max
    local min = math.min

    --- @class (exact) BenchmarkTestSuite
    --- @field N integer
    --- @field setup_suite fun()?
    --- @field setup_round fun()?
    --- @field setup_each fun()?
    --- @field tests table<string, fun()>

    -- luacheck: push ignore _v
    --- @type table<string, BenchmarkTestSuite>
    local test_suites = {
      ["division"] = {
        N = 5000000,
        tests = {
          ["1 / pi"] = function ()
            local _ = 1 / pi
          end,
          ["1 * inv_pi"] = function ()
            local _ = 1 * inv_pi
          end,
        },
      },
      ["floor"] = {
        N = 5000000,
        tests = {
          ["math.floor(n)"] = function ()
            local _ = floor(pi)
          end,
          ["n = n - n % 1"] = function ()
            local _ = pi - (pi % 1)
          end,
        },
      },
      ["abs"] = {
        N = 5000000,
        tests = {
          ["math.abs(n)"] = function ()
            local _ = abs(negative)
          end,
          ["n < 0 and -n or n"] = function ()
            local _ = negative < 0 and -negative or negative
          end,
        },
      },
      ["max"] = {
        N = 5000000,
        tests = {
          ["math.max(n, m)"] = function ()
            local _ = max(n, m)
          end,
          ["n > m and n or m"] = function ()
            local _ = n > m and n or m
          end,
        },
      },
      ["min"] = {
        N = 5000000,
        tests = {
          ["math.min(n, m)"] = function ()
            local _ = min(n, m)
          end,
          ["n < m and n or m"] = function ()
            local _ = n < m and n or m
          end,
        },
      },
      ["var"] = {
        N = 5000000,
        tests = {
          ["Upvalue"] = function ()
            local _ = upvalue + upvalue + upvalue
          end,
          ["Local variable"] = function ()
            local lv = upvalue
            local _ = lv + lv + lv
          end,
        },
      },
      ["table"] = {
        N = 5000000,
        tests = {
          ["Hash-key Access"] = function ()
            local _ = h_table["i1"] + h_table["i50"] + h_table["i100"]
          end,
          ["Array-index Access"] = function ()
            local _ = a_table[1] + a_table[50] + a_table[100]
          end,
        },
      },
      ["loop"] = {
        N = 100000,
        tests = {
          ["pairs() for-loop"] = function ()
            local tbl = h_table
            for _k, _v in pairs(tbl) do end
          end,
          ["ipairs() for-loop"] = function ()
            local tbl = a_table
            for _k, _v in ipairs(tbl) do end
          end,
          ["next() while-loop"] = function ()
            local tbl = h_table
            local _k, _v = next(tbl, nil)
            while _k do _k, _v = next(tbl, _k) end
          end,
          ["Index-based for-loop"] = function ()
            local tbl = a_table
            for i = 1, #tbl do local _v = tbl[i] end
          end,
        },
      },
      ["insert"] = {
        N = 5000000,
        setup_suite = function ()
          test_table = {}
          for i = 1, 1000 do test_table[i] = i end
        end,
        setup_each = function ()
          test_table[1001] = nil
          test_counter = 1000
        end,
        tests = {
          ["table.insert()"] = function ()
            table_insert(test_table, 1)
          end,
          ["tbl[#tbl + 1]"] = function ()
            test_table[#test_table + 1] = 1
          end,
          ["tbl[counter]"] = function ()
            test_counter = test_counter + 1
            test_table[test_counter] = 1
          end,
        },
      },
    }
    -- luacheck: pop

    --- @param str LocalisedString
    --- @param new boolean?
    local function write_log(str, new)
      helpers.write_file(OUT_FILE, { "", str, "\n" }, not new, player_index)
      log(str)
    end
    write_log("### Benchmark results", true)
    write_log(string.format("| %-16s | %-30s | %-22s |", "Category", "Name", "Duration"))
    write_log(string.format("| %s | %s | %s |", string.rep("-", 16), string.rep("-", 30), string.rep("-", 22)))

    for category, ts in pairs(test_suites) do
      if not category_filter or category == category_filter then
        local N = ts.N
        local setup_each = ts.setup_each

        for name, func in pairs(ts.tests) do
          if ts.setup_suite then ts.setup_suite() end

          -- Warm up
          if ts.setup_round then ts.setup_round() end
          for _ = 1, N do
            if setup_each then setup_each() end
            func()
          end

          local profiler = game.create_profiler(true)
          for _ = 1, ROUNDS do
            if ts.setup_round then ts.setup_round() end
            profiler.restart()
            for _ = 1, N do
              if setup_each then setup_each() end
              func()
            end
            profiler.stop()
          end
          profiler.divide(ROUNDS)

          write_log({ "", string.format("| %-16s | %-30s | ", category, name), profiler, " |" })
        end
      end
    end

    game.print('Finished benchmarking. The result has been written to the log file and "' .. OUT_FILE .. '" in script-output directory.')
  end
)
