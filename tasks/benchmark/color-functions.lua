#!/usr/bin/env lua

-- Setup package paths
package.path = "./?.lua;./?/init.lua;./lua_modules/share/lua/5.2/?.lua;" .. package.path

-- Mock Factorio globals
--- @diagnostic disable-next-line: missing-fields
_G.script = { register_metatable = function () end }

local ColorFunctions = require("scripts.runtime.color-functions")

-- Benchmark settings
local ITERATIONS = 1000000 -- 1M calls for each function

-- Prepare input data
local output = { 0, 0, 0 }
local phase = 123.456
local colors = {
  1, 0, 0, -- Red
  0, 1, 0, -- Green
  0, 0, 1, -- Blue
  1, 1, 0, -- Yellow
  0, 1, 1, -- Cyan
  1, 0, 1, -- Magenta
}
local n_colors = #colors / 3
local px, py = 10.5, 20.5
local lx, ly = 15.2, 25.8

-- Helper for benchmarking
local function benchmark(name, func)
  -- Warm up
  for _ = 1, 1000 do
    func(output, phase, colors, n_colors, px, py, lx, ly)
  end

  local start_time = os.clock()
  for _ = 1, ITERATIONS do
    func(output, phase, colors, n_colors, px, py, lx, ly)
  end
  local end_time = os.clock()

  local duration = end_time - start_time
  local ops_per_sec = ITERATIONS / duration
  local avg_time_ns = (duration / ITERATIONS) * 1e9

  print(string.format("%-15s | %10.2f M ops/s | %8.2f ns/op", name, ops_per_sec / 1e6, avg_time_ns))
end

-- Get target functions from command line
local targets = {}
if #arg > 0 then
  for _, a in ipairs(arg) do
    targets[a:lower()] = true
  end
end

-- Run benchmarks
print(string.format("%-15s | %15s | %10s", "Function", "Throughput", "Latency"))
print(string.format("%-15s-+-%15s-+-%11s", string.rep("-", 15), string.rep("-", 15), string.rep("-", 10)))

for i, name in ipairs(ColorFunctions.function_names) do
  if #arg == 0 or targets[name:lower()] or targets[tostring(i)] then
    benchmark(name, ColorFunctions.functions[i])
  end
end
