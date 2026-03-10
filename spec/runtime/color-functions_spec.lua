local ColorFunctions = require("scripts.runtime.color-functions")

describe("ColorFunctions", function ()
  -- Three primary colors as test fixtures
  local colors = {
    { 1, 0, 0 }, -- red
    { 0, 1, 0 }, -- green
    { 0, 0, 1 }, -- blue
  }
  local n_colors = #colors

  -- -------------------------------------------------------------------
  describe("inlined interpolation", function ()
    it("returns the first color exactly at t=0", function ()
      local out = {}
      ColorFunctions.test_inlined_interpolation(out, 0, colors, n_colors, 1.0)
      assert.are.equal(1, out[1])
      assert.are.equal(0, out[2])
      assert.are.equal(0, out[3])
    end)

    it("returns the second color exactly at t=1", function ()
      local out = {}
      ColorFunctions.test_inlined_interpolation(out, 1, colors, n_colors, 1.0)
      assert.are.equal(0, out[1])
      assert.are.equal(1, out[2])
      assert.are.equal(0, out[3])
    end)

    it("linearly interpolates halfway between two colors at t=0.5, sharpness=1", function ()
      local out = {}
      ColorFunctions.test_inlined_interpolation(out, 0.5, colors, n_colors, 1.0)
      assert.are.equal(0.5, out[1])
      assert.are.equal(0.5, out[2])
      assert.are.equal(0, out[3])
    end)

    it("clamps f to 1 when sharpness * f exceeds 1", function ()
      -- t=0.5, sharpness=2.0 => f=1.0 (clamped) => returns second color
      local out = {}
      ColorFunctions.test_inlined_interpolation(out, 0.5, colors, n_colors, 2.0)
      assert.are.equal(0, out[1])
      assert.are.equal(1, out[2])
      assert.are.equal(0, out[3])
    end)

    it("scales f by sharpness when below 1", function ()
      -- t=0.5, sharpness=0.5 => f=0.25 => 25% from red toward green
      local out = {}
      ColorFunctions.test_inlined_interpolation(out, 0.5, colors, n_colors, 0.5)
      assert.are.equal(0.75, out[1])
      assert.are.equal(0.25, out[2])
      assert.are.equal(0, out[3])
    end)

    it("wraps around from the last color to the first", function ()
      -- t=2.5 => between colors[3] (blue) and colors[1] (red)
      -- f=0.5, sharpness=1.0 => midpoint
      local out = {}
      ColorFunctions.test_inlined_interpolation(out, 2.5, colors, n_colors, 1.0)
      assert.are.equal(0.5, out[1])
      assert.are.equal(0, out[2])
      assert.are.equal(0.5, out[3])
    end)

    it("works with a single color (no interpolation partner)", function ()
      local single = { { 0.5, 0.3, 0.8 } }
      local out = {}
      ColorFunctions.test_inlined_interpolation(out, 0, single, 1, 1.0)
      assert.are.equal(0.5, out[1])
      assert.are.equal(0.3, out[2])
      assert.are.equal(0.8, out[3])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("functions", function ()
    local origin = { 0, 0 }

    it("provides exactly 13 color functions", function ()
      assert.are.equal(13, #ColorFunctions.functions)
    end)

    -- Generic properties shared by all 13 functions
    for i = 1, 13 do
      describe(string.format("[%d]", i), function ()
        it("writes three numeric values into output", function ()
          local out = {}
          ColorFunctions.functions[i](out, 0, colors, n_colors, origin[1], origin[2], origin[1], origin[2])
          assert.is_number(out[1])
          assert.is_number(out[2])
          assert.is_number(out[3])
        end)

        it("is deterministic for identical inputs", function ()
          local pos = { 5, 3 }
          local out1, out2 = {}, {}
          ColorFunctions.functions[i](out1, 100, colors, n_colors, origin[1], origin[2], pos[1], pos[2])
          ColorFunctions.functions[i](out2, 100, colors, n_colors, origin[1], origin[2], pos[1], pos[2])
          assert.are.equal(out1[1], out2[1])
          assert.are.equal(out1[2], out2[2])
          assert.are.equal(out1[3], out2[3])
        end)

        it("produces a different result at a different phase", function ()
          -- pos = {4, 3}: chosen so that phase=0 and phase=40 land in different
          -- color segments for all functions (avoids mod-3 period coincidences).
          -- phase=40 (not 1000) is used so that [13] Random's floor(phase/10)
          -- step boundary is also crossed, giving a distinct color.
          local pos = { 4, 3 }
          local out1, out2 = {}, {}
          ColorFunctions.functions[i](out1, 0, colors, n_colors, origin[1], origin[2], pos[1], pos[2])
          ColorFunctions.functions[i](out2, 40, colors, n_colors, origin[1], origin[2], pos[1], pos[2])
          assert.is_true(out1[1] ~= out2[1] or out1[2] ~= out2[2] or out1[3] ~= out2[3])
        end)

        -- [12] Pulse ignores position entirely; skip this test for it.
        if i == 12 then
          it("produces a different result at a different lab position", pending)
        else
          it("produces a different result at a different lab position", function ()
            -- All functions produce distinct colors for these two positions.
            local pos1, pos2 = { 5, 0 }, { 0, 33 }
            local out1, out2 = {}, {}
            ColorFunctions.functions[i](out1, 0, colors, n_colors, origin[1], origin[2], pos1[1], pos1[2])
            ColorFunctions.functions[i](out2, 0, colors, n_colors, origin[1], origin[2], pos2[1], pos2[2])
            assert.is_true(out1[1] ~= out2[1] or out1[2] ~= out2[2] or out1[3] ~= out2[3])
          end)
        end
      end)
    end

    -- Function-specific behaviour
    describe("[1] Radial", function ()
      it("at the same position as the player, depends only on phase", function ()
        -- distance=0, t = phase * inv_40
        -- phase=0  => t=0.0 => red
        -- phase=40 => t=1.0 => green  (integer t, f=0)
        local out1 = {}
        ColorFunctions.functions[1](out1, 0, colors, n_colors, origin[1], origin[2], origin[1], origin[2])
        assert.are.equal(1, out1[1])
        assert.are.equal(0, out1[2])
        assert.are.equal(0, out1[3])

        local out2 = {}
        ColorFunctions.functions[1](out2, 40, colors, n_colors, origin[1], origin[2], origin[1], origin[2])
        assert.are.equal(0, out2[1])
        assert.are.equal(1, out2[2])
        assert.are.equal(0, out2[3])
      end)
    end)

    describe("[2] Angular", function ()
      it("gives opposite-angle labs different colors at the same phase", function ()
        local lab_east = { 10, 0 }  -- theta = 0
        local lab_west = { -10, 0 } -- theta = pi
        local out1, out2 = {}, {}
        ColorFunctions.functions[2](out1, 0, colors, n_colors, origin[1], origin[2], lab_east[1], lab_east[2])
        ColorFunctions.functions[2](out2, 0, colors, n_colors, origin[1], origin[2], lab_west[1], lab_west[2])
        assert.is_true(out1[1] ~= out2[1] or out1[2] ~= out2[2] or out1[3] ~= out2[3])
      end)
    end)

    describe("[3] Horizontal", function ()
      it("returns the same color for labs with equal horizontal distance but different vertical positions", function ()
        local lab_up = { 10, 5 }
        local lab_down = { 10, -5 }
        local out1, out2 = {}, {}
        ColorFunctions.functions[3](out1, 0, colors, n_colors, origin[1], origin[2], lab_up[1], lab_up[2])
        ColorFunctions.functions[3](out2, 0, colors, n_colors, origin[1], origin[2], lab_down[1], lab_down[2])
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
        ColorFunctions.functions[4](out1, 0, colors, n_colors, origin[1], origin[2], lab_left[1], lab_left[2])
        ColorFunctions.functions[4](out2, 0, colors, n_colors, origin[1], origin[2], lab_right[1], lab_right[2])
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
        ColorFunctions.functions[5](out1, 0, colors, n_colors, origin[1], origin[2], lab_a[1], lab_a[2])
        ColorFunctions.functions[5](out2, 0, colors, n_colors, origin[1], origin[2], lab_b[1], lab_b[2])
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
        ColorFunctions.functions[6](out1, 0, colors, n_colors, origin[1], origin[2], lab_a[1], lab_a[2])
        ColorFunctions.functions[6](out2, 0, colors, n_colors, origin[1], origin[2], lab_b[1], lab_b[2])
        assert.are.equal(out1[1], out2[1])
        assert.are.equal(out1[2], out2[2])
        assert.are.equal(out1[3], out2[3])
      end)

      it("returns a different color for labs in adjacent grid cells", function ()
        local lab_cell0 = { 1, 0 }  -- cell (0, 0), sum=0
        local lab_cell1 = { 10, 0 } -- cell (1, 0), sum=1
        local out1, out2 = {}, {}
        ColorFunctions.functions[6](out1, 0, colors, n_colors, origin[1], origin[2], lab_cell0[1], lab_cell0[2])
        ColorFunctions.functions[6](out2, 0, colors, n_colors, origin[1], origin[2], lab_cell1[1], lab_cell1[2])
        assert.is_true(out1[1] ~= out2[1] or out1[2] ~= out2[2] or out1[3] ~= out2[3])
      end)
    end)

    describe("[7] Spiral", function ()
      it("labs at equal distance but different angles have different colors", function ()
        -- Both at distance 8 from player, but at different angles.
        -- Spiral combines radial and angular, so equal distance != equal color.
        local lab_east = { 8, 0 }   -- theta = 0
        local lab_north = { 0, -8 } -- theta = -pi/2
        local out1, out2 = {}, {}
        ColorFunctions.functions[7](out1, 0, colors, n_colors, origin[1], origin[2], lab_east[1], lab_east[2])
        ColorFunctions.functions[7](out2, 0, colors, n_colors, origin[1], origin[2], lab_north[1], lab_north[2])
        assert.is_true(out1[1] ~= out2[1] or out1[2] ~= out2[2] or out1[3] ~= out2[3])
      end)
    end)

    describe("[8] Diamond", function ()
      it("returns the same color for labs on the same Manhattan-distance ring", function ()
        local lab_a = { 8, 0 } -- |dx|+|dy| = 8
        local lab_b = { 4, 4 } -- |dx|+|dy| = 8
        local out1, out2 = {}, {}
        ColorFunctions.functions[8](out1, 0, colors, n_colors, origin[1], origin[2], lab_a[1], lab_a[2])
        ColorFunctions.functions[8](out2, 0, colors, n_colors, origin[1], origin[2], lab_b[1], lab_b[2])
        assert.are.equal(out1[1], out2[1])
        assert.are.equal(out1[2], out2[2])
        assert.are.equal(out1[3], out2[3])
      end)
    end)

    describe("[9] Kaleidoscope", function ()
      it("labs mirrored across both axes have the same color (4-fold symmetry)", function ()
        local lab_ne = { 5, 3 }
        local lab_nw = { -5, 3 }
        local lab_se = { 5, -3 }
        local lab_sw = { -5, -3 }
        local out_ne, out_nw, out_se, out_sw = {}, {}, {}, {}
        ColorFunctions.functions[9](out_ne, 0, colors, n_colors, origin[1], origin[2], lab_ne[1], lab_ne[2])
        ColorFunctions.functions[9](out_nw, 0, colors, n_colors, origin[1], origin[2], lab_nw[1], lab_nw[2])
        ColorFunctions.functions[9](out_se, 0, colors, n_colors, origin[1], origin[2], lab_se[1], lab_se[2])
        ColorFunctions.functions[9](out_sw, 0, colors, n_colors, origin[1], origin[2], lab_sw[1], lab_sw[2])
        assert.are.equal(out_ne[1], out_nw[1])
        assert.are.equal(out_ne[2], out_nw[2])
        assert.are.equal(out_ne[3], out_nw[3])
        assert.are.equal(out_ne[1], out_se[1])
        assert.are.equal(out_ne[2], out_se[2])
        assert.are.equal(out_ne[3], out_se[3])
        assert.are.equal(out_ne[1], out_sw[1])
        assert.are.equal(out_ne[2], out_sw[2])
        assert.are.equal(out_ne[3], out_sw[3])
      end)
    end)

    describe("[10] Square", function ()
      it("returns the same color for labs on the same Chebyshev ring", function ()
        -- max(|dx|, |dy|) = 8 for both
        local lab_a = { 8, 0 } -- max(8, 0) = 8
        local lab_b = { 4, 8 } -- max(4, 8) = 8
        local out1, out2 = {}, {}
        ColorFunctions.functions[10](out1, 0, colors, n_colors, origin[1], origin[2], lab_a[1], lab_a[2])
        ColorFunctions.functions[10](out2, 0, colors, n_colors, origin[1], origin[2], lab_b[1], lab_b[2])
        assert.are.equal(out1[1], out2[1])
        assert.are.equal(out1[2], out2[2])
        assert.are.equal(out1[3], out2[3])
      end)
    end)

    describe("[11] Lattice", function ()
      it("returns the same color for labs 32 tiles apart (repeating tile)", function ()
        local lab_a = { 4, 3 }
        local lab_b = { 36, 3 } -- 4 + 32
        local out1, out2 = {}, {}
        ColorFunctions.functions[11](out1, 0, colors, n_colors, origin[1], origin[2], lab_a[1], lab_a[2])
        ColorFunctions.functions[11](out2, 0, colors, n_colors, origin[1], origin[2], lab_b[1], lab_b[2])
        assert.are.equal(out1[1], out2[1])
        assert.are.equal(out1[2], out2[2])
        assert.are.equal(out1[3], out2[3])
      end)

      it("returns the same color for labs mirrored within a 32-tile cell", function ()
        -- fx=5 and fx=32-5=27 fold to the same distance from the nearest grid corner
        local lab_a = { 5, 3 }
        local lab_b = { 27, 3 }
        local out1, out2 = {}, {}
        ColorFunctions.functions[11](out1, 0, colors, n_colors, origin[1], origin[2], lab_a[1], lab_a[2])
        ColorFunctions.functions[11](out2, 0, colors, n_colors, origin[1], origin[2], lab_b[1], lab_b[2])
        assert.are.equal(out1[1], out2[1])
        assert.are.equal(out1[2], out2[2])
        assert.are.equal(out1[3], out2[3])
      end)
    end)

    describe("[12] Pulse", function ()
      it("all labs produce the same color regardless of position", function ()
        local pos_a = { 5, 0 }
        local pos_b = { 1, 10 }
        local out1, out2 = {}, {}
        ColorFunctions.functions[12](out1, 0, colors, n_colors, origin[1], origin[2], pos_a[1], pos_a[2])
        ColorFunctions.functions[12](out2, 0, colors, n_colors, origin[1], origin[2], pos_b[1], pos_b[2])
        assert.are.equal(out1[1], out2[1])
        assert.are.equal(out1[2], out2[2])
        assert.are.equal(out1[3], out2[3])
      end)
    end)

    describe("[13] Random", function ()
      it("returns the same color for the same lab position at the same phase step", function ()
        -- Phase steps change every 10 ticks; the same step => same color.
        local pos = { 5, 3 }
        local out1, out2 = {}, {}
        ColorFunctions.functions[13](out1, 5, colors, n_colors, origin[1], origin[2], pos[1], pos[2])
        ColorFunctions.functions[13](out2, 9, colors, n_colors, origin[1], origin[2], pos[1], pos[2])
        assert.are.equal(out1[1], out2[1])
        assert.are.equal(out1[2], out2[2])
        assert.are.equal(out1[3], out2[3])
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
