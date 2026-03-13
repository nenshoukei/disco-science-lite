local ColorFunctions = require("scripts.runtime.color-functions")

local N = 100000
local ROUNDS = 10

local MS_PER_TICK = 1000 / 60

-- ID-to-Name map for translation callbacks
local pending_translations = {}

script.on_event(defines.events.on_string_translated, function (event)
  local result = event.result
  local name = pending_translations[event.id]
  if name then
    local total_ms = tonumber(string.match(event.result, "([%d%.]+)"))
    if total_ms then
      local ms_per_op = total_ms / N
      local ops_per_ms = 1 / ms_per_op
      local ops_per_tick = ops_per_ms * MS_PER_TICK
      print(string.format("%-30s: Total %7.2f ms, Avg %.8s ms; %9.4f ops/ms, %9.4f ops/tick", name, total_ms,
        ms_per_op,
        ops_per_ms, ops_per_tick))
    else
      print(string.format("%-30s: %s", name, result))
    end
    pending_translations[event.id] = nil
  end
  if not next(pending_translations) then
    game.print("Finished benchmarks. See console for the results.")
  end
end)

--- @generic T : { name: string }
--- @param test_cases T[]
--- @param parameter string?
--- @return T[]
local function filter_test_cases(test_cases, parameter)
  if not parameter then return test_cases end

  -- Parse targets from parameter
  local targets = {}
  for target in string.gmatch(parameter, "([^,]+)") do
    targets[string.lower(string.gsub(target, "%s+", ""))] = true
  end
  if not next(targets) then return test_cases end

  -- Filter test cases
  local filtered = {}
  for _, tc in ipairs(test_cases) do
    local lower_name = string.lower(tc.name)
    for target in pairs(targets) do
      if string.find(lower_name, target, 1, true) then
        table.insert(filtered, tc)
        break
      end
    end
  end

  return filtered
end

commands.add_command(
  "ds-bench",
  "Run experimental benchmark. Usage: /ds-bench",
  function (event)
    local player = game.get_player(event.player_index)
    if not player then return end

    local pi = math.pi
    local inv_pi = 1 / pi
    local h_table = { x = 1, y = 2, z = 3 }
    local a_table = { 1, 2, 3 }
    local upvalue = 1
    local test_table = {}
    local test_counter = 1
    local table_insert = table.insert

    --- @type { name: string, setup: fun()?, func: fun() }[]
    local test_cases = {
      {
        name = "math: Division",
        func = function ()
          local _ = 1 / pi
        end,
      },
      {
        name = "math: Multiplication",
        func = function ()
          local _ = 1 * inv_pi
        end,
      },
      {
        name = "table: Hash-key Access",
        func = function ()
          local _ = h_table.x + h_table.y + h_table.z
        end,
      },
      {
        name = "table: Array-index Access",
        func = function ()
          local _ = a_table[1] + a_table[2] + a_table[3]
        end,
      },
      {
        name = "var: Upvalue",
        func = function ()
          local _ = upvalue + upvalue
        end,
      },
      {
        name = "var: Local variable",
        func = function ()
          local lv = upvalue
          local _ = lv + lv
        end,
      },
      {
        name = "loop: Index-based for-loop",
        func = function ()
          local tbl = a_table
          for i = 1, #tbl do
            local _ = a_table[i]
          end
        end,
      },
      {
        name = "loop: ipairs() for-loop",
        func = function ()
          local tbl = a_table
          for _k, _v in ipairs(tbl) do
          end
        end,
      },
      {
        name = "loop: pairs() for-loop",
        func = function ()
          local tbl = h_table
          for _k, _v in pairs(tbl) do
          end
        end,
      },
      {
        name = "loop: next() while-loop",
        func = function ()
          local tbl = h_table
          local _k, _ = next(tbl, nil)
          while _k do
            _k, _ = next(tbl, _k)
          end
        end,
      },
      {
        name = "insert: table.insert()",
        setup = function () test_table = {} end,
        func = function ()
          table_insert(test_table, 1)
        end,
      },
      {
        name = "insert: tbl[#tbl + 1]",
        setup = function () test_table = {} end,
        func = function ()
          test_table[#test_table + 1] = 1
        end,
      },
      {
        name = "insert: tbl[counter]",
        setup = function ()
          test_table = {}
          test_counter = 1
        end,
        func = function ()
          test_table[test_counter] = 1
          test_counter = test_counter + 1
        end,
      },
    }

    test_cases = filter_test_cases(test_cases, event.parameter)
    if #test_cases == 0 then
      player.print("No matching benchmark cases found.")
      return
    end

    print(string.format("--- Benchmarking %d cases (N=%d, ROUNDS=%d) ---", #test_cases, N, ROUNDS))
    local results = {}
    for _, tc in ipairs(test_cases) do
      local func = tc.func

      -- Warm up
      for _ = 1, N do
        func()
      end

      local p = game.create_profiler()
      for _ = 1, ROUNDS do
        for _ = 1, N do
          func()
        end
      end
      p.stop()
      p.divide(ROUNDS)

      results[tc.name] = p
    end

    for name, result in pairs(results) do
      local id = player.request_translation(result)
      if id then
        pending_translations[id] = name
      end
    end
  end
)

commands.add_command(
  "ds-bench-color",
  "Run color functions benchmark. Usage: /ds-bench-color [target1,target2,...]",
  function (event)
    local output = { 0, 0, 0 }
    local phase = 123.456 -- Simulating a pre-scaled phase
    local colors = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
    local n_colors = 3
    local px, py = 10.5, 20.5
    local lx, ly = 15.2, 25.8
    local player = game.get_player(event.player_index)
    if not player then return end

    local test_cases = {}
    for i, name in ipairs(ColorFunctions.function_names) do
      table.insert(test_cases, { name = name, func = ColorFunctions.functions[i] })
    end

    test_cases = filter_test_cases(test_cases, event.parameter)
    if #test_cases == 0 then
      player.print("No matching benchmark cases found.")
      return
    end

    print(string.format("--- Benchmarking %d cases (N=%d, ROUNDS=%d) ---", #test_cases, N, ROUNDS))
    local results = {}
    for _, tc in ipairs(test_cases) do
      -- Warm up
      for _ = 1, N do
        tc.func(output, phase, colors, n_colors, px, py, lx, ly)
      end

      local p = game.create_profiler()
      for _ = 1, ROUNDS do
        for _ = 1, N do
          tc.func(output, phase, colors, n_colors, px, py, lx, ly)
        end
      end
      p.stop()
      p.divide(ROUNDS)

      results[tc.name] = p
    end

    for name, result in pairs(results) do
      local id = player.request_translation(result)
      if id then
        pending_translations[id] = name
      end
    end
  end)
