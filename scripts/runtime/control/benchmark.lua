local ColorFunctions = require("scripts.runtime.color-functions")

-- ID-to-Name map for translation callbacks
local pending_translations = {}

script.on_event(defines.events.on_string_translated, function (event)
  local name = pending_translations[event.id]
  if name then
    print(string.format("%-20s: %s", name, event.result))
    pending_translations[event.id] = nil
  end
end)

commands.add_command("ds-bench", "Run color functions benchmark. Usage: /ds-bench [target1,target2,...]", function (
  event)
  local iterations = 100000
  local output = { 0, 0, 0 }
  local phase = 123.456
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

  -- [OPTIMIZATION TESTS]
  -- table.insert(all_cases, {
  --   name = "Exp: Grid Inline",
  --   func = ColorFunctions._compile_function("GridInline", [[
  --     local dx = (lx - px) * INV_9
  --     local dy = (ly - py) * INV_8
  --     -- x - x % 1 is equivalent to floor(x) in Lua 5.2
  --     local fdx = dx - dx % 1
  --     local fdy = dy - dy % 1
  --     local val = fdx + fdy
  --     t = (val < 0 and -val or val) + phase * INV_10
  --   ]], 5),
  -- })

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

  print(string.format("--- Benchmarking %d cases ---", #test_cases))
  for _, tc in ipairs(test_cases) do
    local p = game.create_profiler()
    for _ = 1, iterations do
      tc.func(output, phase, colors, n_colors, px, py, lx, ly)
    end
    p.stop()
    local id = player.request_translation(p)
    if id then
      pending_translations[id] = tc.name
    end
  end
end)
