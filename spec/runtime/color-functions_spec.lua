local ColorFunctions = require("scripts.runtime.color-functions")

describe("ColorFunctions", function ()
  -- Three primary colors as test fixtures
  local colors = {
    { 1, 0, 0 }, -- red
    { 0, 1, 0 }, -- green
    { 0, 0, 1 }, -- blue
  }
  local n = #colors

  -- -------------------------------------------------------------------
  describe("loop_interpolate", function ()
    it("returns the first color exactly at t=0", function ()
      local out = {}
      ColorFunctions.loop_interpolate(out, 0, colors, n, 1.0)
      assert.are.equal(1, out[1])
      assert.are.equal(0, out[2])
      assert.are.equal(0, out[3])
    end)

    it("returns the second color exactly at t=1", function ()
      local out = {}
      ColorFunctions.loop_interpolate(out, 1, colors, n, 1.0)
      assert.are.equal(0, out[1])
      assert.are.equal(1, out[2])
      assert.are.equal(0, out[3])
    end)

    it("linearly interpolates halfway between two colors at t=0.5, sharpness=1", function ()
      local out = {}
      ColorFunctions.loop_interpolate(out, 0.5, colors, n, 1.0)
      assert.are.equal(0.5, out[1])
      assert.are.equal(0.5, out[2])
      assert.are.equal(0, out[3])
    end)

    it("clamps f to 1 when sharpness * f exceeds 1", function ()
      -- t=0.5, sharpness=2.0 => f=1.0 (clamped) => returns second color
      local out = {}
      ColorFunctions.loop_interpolate(out, 0.5, colors, n, 2.0)
      assert.are.equal(0, out[1])
      assert.are.equal(1, out[2])
      assert.are.equal(0, out[3])
    end)

    it("scales f by sharpness when below 1", function ()
      -- t=0.5, sharpness=0.5 => f=0.25 => 25% from red toward green
      local out = {}
      ColorFunctions.loop_interpolate(out, 0.5, colors, n, 0.5)
      assert.are.equal(0.75, out[1])
      assert.are.equal(0.25, out[2])
      assert.are.equal(0, out[3])
    end)

    it("wraps around from the last color to the first", function ()
      -- t=2.5 => between colors[3] (blue) and colors[1] (red)
      -- f=0.5, sharpness=1.0 => midpoint
      local out = {}
      ColorFunctions.loop_interpolate(out, 2.5, colors, n, 1.0)
      assert.are.equal(0.5, out[1])
      assert.are.equal(0, out[2])
      assert.are.equal(0.5, out[3])
    end)

    it("works with a single color (no interpolation partner)", function ()
      local single = { { 0.5, 0.3, 0.8 } }
      local out = {}
      ColorFunctions.loop_interpolate(out, 0, single, 1, 1.0)
      assert.are.equal(0.5, out[1])
      assert.are.equal(0.3, out[2])
      assert.are.equal(0.8, out[3])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("functions", function ()
    local origin = { 0, 0 }

    it("provides exactly 6 color functions", function ()
      assert.are.equal(6, #ColorFunctions.functions)
    end)

    -- Generic properties shared by all 6 functions
    for i = 1, 6 do
      describe(string.format("[%d]", i), function ()
        it("writes three numeric values into output", function ()
          local out = {}
          ColorFunctions.functions[i](out, 0, colors, origin, origin)
          assert.is_number(out[1])
          assert.is_number(out[2])
          assert.is_number(out[3])
        end)

        it("is deterministic for identical inputs", function ()
          local pos = { 5, 3 }
          local out1, out2 = {}, {}
          ColorFunctions.functions[i](out1, 100, colors, origin, pos)
          ColorFunctions.functions[i](out2, 100, colors, origin, pos)
          assert.are.equal(out1[1], out2[1])
          assert.are.equal(out1[2], out2[2])
          assert.are.equal(out1[3], out2[3])
        end)

        it("produces a different result at a different tick", function ()
          -- pos = {4, 3}: chosen so that tick=0 and tick=1000 land in different
          -- color segments for all 6 functions (avoids mod-3 period coincidences).
          local pos = { 4, 3 }
          local out1, out2 = {}, {}
          ColorFunctions.functions[i](out1, 0, colors, origin, pos)
          ColorFunctions.functions[i](out2, 1000, colors, origin, pos)
          assert.is_true(out1[1] ~= out2[1] or out1[2] ~= out2[2] or out1[3] ~= out2[3])
        end)

        it("produces a different result at a different lab position", function ()
          -- pos1/pos2 differ in both x and y so that distance, angle, horizontal,
          -- vertical, and diagonal components all differ across all 6 functions.
          local pos1 = { 5, 0 }
          local pos2 = { 3, 10 }
          local out1, out2 = {}, {}
          ColorFunctions.functions[i](out1, 0, colors, origin, pos1)
          ColorFunctions.functions[i](out2, 0, colors, origin, pos2)
          assert.is_true(out1[1] ~= out2[1] or out1[2] ~= out2[2] or out1[3] ~= out2[3])
        end)
      end)
    end

    -- Function-specific behaviour
    describe("[1] Radial", function ()
      it("at the same position as the player, depends only on tick", function ()
        -- distance=0, t = tick * inv_40
        -- tick=0  => t=0.0 => red
        -- tick=40 => t=1.0 => green  (integer t, f=0)
        local out1 = {}
        ColorFunctions.functions[1](out1, 0, colors, origin, origin)
        assert.are.equal(1, out1[1])
        assert.are.equal(0, out1[2])
        assert.are.equal(0, out1[3])

        local out2 = {}
        ColorFunctions.functions[1](out2, 40, colors, origin, origin)
        assert.are.equal(0, out2[1])
        assert.are.equal(1, out2[2])
        assert.are.equal(0, out2[3])
      end)
    end)

    describe("[2] Angular", function ()
      it("gives opposite-angle labs different colors at the same tick", function ()
        local lab_east = { 10, 0 }  -- theta = 0
        local lab_west = { -10, 0 } -- theta = pi
        local out1, out2 = {}, {}
        ColorFunctions.functions[2](out1, 0, colors, origin, lab_east)
        ColorFunctions.functions[2](out2, 0, colors, origin, lab_west)
        assert.is_true(out1[1] ~= out2[1] or out1[2] ~= out2[2] or out1[3] ~= out2[3])
      end)
    end)

    describe("[3] Horizontal", function ()
      it("returns the same color for labs with equal horizontal distance but different vertical positions", function ()
        local lab_up = { 10, 5 }
        local lab_down = { 10, -5 }
        local out1, out2 = {}, {}
        ColorFunctions.functions[3](out1, 0, colors, origin, lab_up)
        ColorFunctions.functions[3](out2, 0, colors, origin, lab_down)
        assert.are.equal(out1[1], out2[1])
        assert.are.equal(out1[2], out2[2])
        assert.are.equal(out1[3], out2[3])
      end)
    end)

    describe("[4] Vertical", function ()
      it("returns the same color for labs with equal vertical distance but different horizontal positions", function ()
        local lab_left = { -5, 10 }
        local lab_right = { 5, 10 }
        local out1, out2 = {}, {}
        ColorFunctions.functions[4](out1, 0, colors, origin, lab_left)
        ColorFunctions.functions[4](out2, 0, colors, origin, lab_right)
        assert.are.equal(out1[1], out2[1])
        assert.are.equal(out1[2], out2[2])
        assert.are.equal(out1[3], out2[3])
      end)
    end)

    describe("[5] Diagonal", function ()
      it("returns the same color for labs equidistant along the diagonal axis", function ()
        -- |dx + dy| is the same for both
        local lab_a = { 10, 0 } -- |10+0| = 10
        local lab_b = { 0, 10 } -- |0+10| = 10
        local out1, out2 = {}, {}
        ColorFunctions.functions[5](out1, 0, colors, origin, lab_a)
        ColorFunctions.functions[5](out2, 0, colors, origin, lab_b)
        assert.are.equal(out1[1], out2[1])
        assert.are.equal(out1[2], out2[2])
        assert.are.equal(out1[3], out2[3])
      end)
    end)

    describe("[6] Grid", function ()
      it("returns the same color for labs in the same grid cell", function ()
        -- Grid is 9x8 units; labs within the same cell share the same color
        local lab_a = { 1, 1 } -- cell (0, 0)
        local lab_b = { 4, 3 } -- cell (0, 0)
        local out1, out2 = {}, {}
        ColorFunctions.functions[6](out1, 0, colors, origin, lab_a)
        ColorFunctions.functions[6](out2, 0, colors, origin, lab_b)
        assert.are.equal(out1[1], out2[1])
        assert.are.equal(out1[2], out2[2])
        assert.are.equal(out1[3], out2[3])
      end)

      it("returns a different color for labs in adjacent grid cells", function ()
        local lab_cell0 = { 1, 0 }  -- cell (0, 0), sum=0
        local lab_cell1 = { 10, 0 } -- cell (1, 0), sum=1
        local out1, out2 = {}, {}
        ColorFunctions.functions[6](out1, 0, colors, origin, lab_cell0)
        ColorFunctions.functions[6](out2, 0, colors, origin, lab_cell1)
        assert.is_true(out1[1] ~= out2[1] or out1[2] ~= out2[2] or out1[3] ~= out2[3])
      end)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("choose_random", function ()
    local n_functions = #ColorFunctions.functions

    it("returned function matches functions[returned_index]", function ()
      for _ = 1, 50 do
        local fn, idx = ColorFunctions.choose_random(1)
        assert.are.equal(ColorFunctions.functions[idx], fn)
      end
    end)

    it("returned index is within [1, n] range", function ()
      for _ = 1, 50 do
        local _, idx = ColorFunctions.choose_random(1)
        assert.is_true(idx >= 1 and idx <= n_functions)
      end
    end)

    it("never returns the previous index", function ()
      -- The algorithm guarantees new_index != prev_index deterministically,
      -- so a small number of samples per prev_index is sufficient.
      for prev = 1, n_functions do
        for _ = 1, 20 do
          local _, idx = ColorFunctions.choose_random(prev)
          assert.are_not.equal(prev, idx)
        end
      end
    end)

    it("accepts nil prev_index and returns a valid index", function ()
      for _ = 1, 20 do
        local fn, idx = ColorFunctions.choose_random(nil)
        assert.is_true(idx >= 1 and idx <= n_functions)
        assert.are.equal(ColorFunctions.functions[idx], fn)
      end
    end)
  end)
end)
