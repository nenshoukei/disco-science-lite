local ColorFunctions = require("scripts.runtime.color-functions")

local N = 10000
local ROUNDS = 10

commands.add_command(
  "ds-bench-color",
  "Run color functions benchmark. Usage: /ds-bench-color",
  function ()
    local output = { 0, 0, 0 }
    local phase = 123.456 -- Simulating a pre-scaled phase
    local colors = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
    local n_colors = 3
    local scale = 1.0
    local px, py = 10.5, 20.5
    local lx, ly = 15.2, 25.8

    --- @type table<string, LuaProfiler>
    local results = {}
    for i, name in ipairs(ColorFunctions.function_names) do
      local func = ColorFunctions.functions[i]

      -- Warm up
      for _ = 1, N do
        func(output, phase, colors, n_colors, scale, px, py, lx, ly)
      end

      local p = game.create_profiler()
      for _ = 1, ROUNDS do
        for _ = 1, N do
          func(output, phase, colors, n_colors, scale, px, py, lx, ly)
        end
      end
      p.stop()
      p.divide(ROUNDS)

      results[name] = p
    end

    log(string.format("### Benchmark results (N=%d, ROUNDS=%d)", table_size(results), N, ROUNDS))
    for name, result in pairs(results) do
      local padded_name = string.format("%-16s: ", name)
      log({ "", "| ", padded_name, " | ", result, " |" })
    end
    game.print("Finished benchmarking. The result has been written to the log file.")
  end
)
