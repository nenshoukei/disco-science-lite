local ColorFunctions = require("scripts.runtime.color-functions")

local N = 100000
local ROUNDS = 10

-- ID-to-Name map for translation callbacks
local pending_translations = {}

script.on_event(defines.events.on_string_translated, function (event)
  local result = event.result
  local name = pending_translations[event.id]
  if name then
    local total_ms = tonumber(string.match(event.result, "([%d%.]+)%s*ms"))
    if total_ms then
      local per_op = total_ms / N
      print(string.format("%-20s: %s  (%.8fms/op)", name, result, per_op))
    else
      print(string.format("%-20s: %s", name, result))
    end
    pending_translations[event.id] = nil
  end
end)

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

    --- @type { name: string, func: fun() }[]
    local test_cases = {
      {
        name = "Division",
        func = function ()
          local _ = 1 / pi
        end,
      },
      {
        name = "Multiplication",
        func = function ()
          local _ = 1 * inv_pi
        end,
      },
      {
        name = "Hash-key Access",
        func = function ()
          local _ = h_table.x + h_table.y
        end,
      },
      {
        name = "Array-index Access",
        func = function ()
          local _ = a_table[1] + a_table[2]
        end,
      },
      {
        name = "Upvalue",
        func = function ()
          local _ = upvalue + upvalue
        end,
      },
      {
        name = "Local variable",
        func = function ()
          local lv = upvalue
          local _ = lv + lv
        end,
      },
      {
        name = "Index-based for-loop",
        func = function ()
          local tbl = a_table
          for i = 1, #tbl do
            local _ = a_table[i]
          end
        end,
      },
      {
        name = "ipairs() for-loop",
        func = function ()
          local tbl = a_table
          for _k, _v in ipairs(tbl) do
          end
        end,
      },
      {
        name = "pairs() for-loop",
        func = function ()
          local tbl = h_table
          for _k, _v in pairs(tbl) do
          end
        end,
      },
      {
        name = "next() while-loop",
        func = function ()
          local tbl = h_table
          local _k, _ = next(tbl, nil)
          while _k do
            _k, _ = next(tbl, _k)
          end
        end,
      },
    }

    print(string.format("--- Benchmarking %d cases (N=%d, ROUNDS=%d) ---", #test_cases, N, ROUNDS))
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
      local id = player.request_translation(p)
      if id then
        pending_translations[id] = tc.name
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

    -- Parse targets from event.parameter
    local targets = {}
    if event.parameter then
      for target in string.gmatch(event.parameter, "([^,]+)") do
        targets[string.lower(string.gsub(target, "%s+", ""))] = true
      end
    end

    local all_cases = {}
    -- Standard functions
    for i, name in ipairs(ColorFunctions.function_names) do
      table.insert(all_cases, { name = name, func = ColorFunctions.functions[i] })
    end

    -- Filter test cases
    local test_cases = {}
    if next(targets) then
      for _, tc in ipairs(all_cases) do
        local lower_name = string.lower(tc.name)
        for target in pairs(targets) do
          if string.find(lower_name, target, 1, true) then
            table.insert(test_cases, tc)
            break
          end
        end
      end
    else
      test_cases = all_cases
    end

    if #test_cases == 0 then
      player.print("No matching benchmark cases found.")
      return
    end

    print(string.format("--- Benchmarking %d cases (N=%d, ROUNDS=%d) ---", #test_cases, N, ROUNDS))
    for _, tc in ipairs(test_cases) do
      local p = game.create_profiler()
      for _ = 1, ROUNDS do
        for _ = 1, N do
          tc.func(output, phase, colors, n_colors, px, py, lx, ly)
        end
      end
      p.stop()
      p.divide(ROUNDS)
      local id = player.request_translation(p)
      if id then
        pending_translations[id] = tc.name
      end
    end
  end)
