local ChunkMap = require("scripts.runtime.chunk-map")

--- Create a minimal LabOverlay-like value for ChunkMap tests.
--- ChunkMap.remove() checks overlay[OVERLAY_UNIT_NUM] for the unit_number.
--- @param unit_number number
--- @return LabOverlay
local function make_overlay(unit_number)
  return ({ unit_number = unit_number }) --[[@as LabOverlay]]
end

--- Create a mock LuaEntity.
--- @param unit_number number
--- @param surface_index number
--- @param x number
--- @param y number
--- @return LuaEntity
local function make_entity(unit_number, surface_index, x, y)
  return ({
    unit_number = unit_number,
    surface_index = surface_index,
    position = { x = x, y = y },
  }) --[[@as LuaEntity]]
end

describe("ChunkMap", function ()
  -- -------------------------------------------------------------------
  describe("new", function ()
    it("creates an empty map", function ()
      local m = ChunkMap.new()
      assert.are.same({}, m.data)
      assert.are.same({}, m.entries)
      assert.are.same({}, m.surface_bounds)
      assert.are.same({}, m.surface_bounds_dirty)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("insert", function ()
    it("adds an entry to entries and chunk data", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 0, 0)
      local v = make_overlay(1)
      m:insert(e, v)
      assert.is_not_nil(m.entries[1])
      local chunks = m.data[1]
      assert.is_not_nil(chunks)
    end)

    it("marks surface as dirty", function ()
      local m = ChunkMap.new()
      m:insert(make_entity(1, 1, 0, 0), make_overlay(1))
      assert.is_true(m.surface_bounds_dirty[1])
    end)

    it("does not mark dirty when updating overlay in-place (same keys)", function ()
      local m = ChunkMap.new()
      m:insert(make_entity(1, 1, 0, 0), make_overlay(1))
      m.surface_bounds_dirty[1] = nil                    -- clear dirty
      m:insert(make_entity(1, 1, 0, 0), make_overlay(1)) -- same position
      assert.is_nil(m.surface_bounds_dirty[1])
    end)

    it("places the overlay in the correct chunk", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 16, 16)
      local v = make_overlay(1)
      m:insert(e, v)
      local chunks = m.data[1]
      assert.is_not_nil(chunks) --- @cast chunks -nil
      assert.is_not_nil(chunks[0])
      assert.is_not_nil(chunks[0][0])
      assert.are.equal(v, chunks[0][0][1])
    end)

    it("stores surface_index, cx, cy, overlay in the entry", function ()
      local m = ChunkMap.new()
      local e = make_entity(5, 10, 40, 80) -- chunk at (1, 2)
      local v = make_overlay(5)
      m:insert(e, v)
      local entry = m.entries[5]
      assert.are.equal(10, entry.surface_index)
      assert.are.equal(1, entry.chunk_x)
      assert.are.equal(2, entry.chunk_y)
      assert.are.equal(1, entry.index)
      assert.are.equal(v, entry.overlay)
    end)

    it("updates the entry if it has the same keys as before", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 0, 0)
      local v1 = make_overlay(1)
      local v2 = make_overlay(1)
      m:insert(e, v1)
      m:insert(e, v2)
      local chunks = m.data[1]
      assert.is_not_nil(chunks) --- @cast chunks -nil
      -- Only one entry should remain in the chunk
      assert.are.equal(1, #chunks[0][0])
      assert.are.equal(v2, chunks[0][0][1])
    end)

    it("re-inserts if chunk coordinates changed", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 0, 0) -- chunk (0,0)
      local v = make_overlay(1)
      m:insert(e, v)

      -- Change position to chunk (1,2)
      e.position = { x = 32, y = 64 }
      m:insert(e, v)

      -- Old chunk should be empty/nil
      assert.is_nil(m.data[1][0])
      -- New chunk should have the entry
      assert.are.equal(v, m.data[1][1][2][1])
      -- Entry should be updated
      local entry = m.entries[1]
      assert.are.equal(1, entry.chunk_x)
      assert.are.equal(2, entry.chunk_y)
    end)

    it("re-inserts if surface changed", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 0, 0) -- surface 1
      local v = make_overlay(1)
      m:insert(e, v)

      -- Change surface
      e.surface_index = 2
      m:insert(e, v)

      -- Old surface should be empty/nil
      assert.is_nil(m.data[1])
      -- New surface should have the entry
      assert.are.equal(v, m.data[2][0][0][1])
      -- Entry should be updated
      assert.are.equal(2, m.entries[1].surface_index)
    end)

    it("does nothing when entity has no unit_number", function ()
      local m = ChunkMap.new()
      local e = ({
        unit_number = nil,
        surface_index = 1,
        position = { x = 0, y = 0 },
      }) --[[@as LuaEntity]]
      m:insert(e, make_overlay(0))
      assert.are.same({}, m.data)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("remove", function ()
    it("removes the entry from entries and chunk data", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 0, 0)
      m:insert(e, make_overlay(1))
      m:remove(1)
      assert.is_nil(m.entries[1])
      assert.is_nil(m.data[1])
    end)

    it("marks surface as dirty", function ()
      local m = ChunkMap.new()
      m:insert(make_entity(1, 1, 0, 0), make_overlay(1))
      m:insert(make_entity(2, 1, 2, 0), make_overlay(2))
      m.surface_bounds_dirty[1] = nil -- clear dirty from insert
      m:remove(1)
      assert.is_true(m.surface_bounds_dirty[1])
    end)

    it("does nothing for unknown unit_number", function ()
      local m = ChunkMap.new()
      m:remove(999) -- should not error
      assert.are.same({}, m.data)
    end)

    it("uses swap-and-pop, keeping remaining entries intact", function ()
      local m = ChunkMap.new()
      -- Insert A, B, C, D all in the same chunk (surface 1, position ~(0,0))
      local va = make_overlay(10)
      local vb = make_overlay(20)
      local vc = make_overlay(30)
      local vd = make_overlay(40)
      m:insert(make_entity(10, 1, 0, 0), va)
      m:insert(make_entity(20, 1, 0, 0), vb)
      m:insert(make_entity(30, 1, 0, 0), vc)
      m:insert(make_entity(40, 1, 0, 0), vd)

      m:remove(20) -- remove B

      -- Swap-and-popped: A, B, C, D → A, D, C
      local chunk = m.data[1][0][0]
      assert.are.equal(3, #chunk)
      assert.are.equal(va, chunk[1])
      assert.are.equal(vd, chunk[2])
      assert.are.equal(vc, chunk[3])

      -- All remaining unit numbers must still be present in entries
      assert.is_not_nil(m.entries[10])
      assert.is_nil(m.entries[20])
      assert.is_not_nil(m.entries[30])
      assert.is_not_nil(m.entries[40])

      -- .index should be updated
      assert.are.equal(1, m.entries[10].index)
      assert.are.equal(2, m.entries[40].index)
      assert.are.equal(3, m.entries[30].index)
    end)

    it("removes empty chunk column and surface table", function ()
      local m = ChunkMap.new()
      local e = make_entity(1, 1, 0, 0)
      m:insert(e, make_overlay(1))
      m:remove(1)
      assert.is_nil(m.data[1]) -- entire surface entry cleaned up
      assert.is_nil(m.surface_bounds[1])
      assert.is_nil(m.surface_bounds_dirty[1])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("update_surface_bounds", function ()
    it("computes expanded bounds from chunk data", function ()
      local m = ChunkMap.new()
      m:insert(make_entity(1, 1, 16, 16), make_overlay(1)) -- chunk (0, 0)
      m.max_reach_x = 100
      m.max_reach_y = 50
      m:update_surface_bounds(1)
      local bounds = m.surface_bounds[1]
      assert.is_not_nil(bounds) --- @cast bounds -nil
      -- min_cx=0, max_cx=0 → tile range [0, 32]; expanded → [-100, 132]
      -- min_cy=0, max_cy=0 → tile range [0, 32]; expanded → [-50, 82]
      assert.are.equal(-100, bounds[1]) -- left
      assert.are.equal(-50, bounds[2])  -- top
      assert.are.equal(132, bounds[3])  -- right
      assert.are.equal(82, bounds[4])   -- bottom
    end)

    it("handles multiple labs spanning different chunks", function ()
      local m = ChunkMap.new()
      m:insert(make_entity(1, 1, 0, 0), make_overlay(1))   -- chunk (0, 0)
      m:insert(make_entity(2, 1, 64, 64), make_overlay(2)) -- chunk (2, 2)
      m.max_reach_x = 10
      m.max_reach_y = 5
      m:update_surface_bounds(1)
      local bounds = m.surface_bounds[1]
      assert.is_not_nil(bounds) --- @cast bounds -nil
      -- min_cx=0, max_cx=2 → tile range [0, 96]; expanded → [-10, 106]
      -- min_cy=0, max_cy=2 → tile range [0, 96]; expanded → [-5, 101]
      assert.are.equal(-10, bounds[1])
      assert.are.equal(-5, bounds[2])
      assert.are.equal(106, bounds[3])
      assert.are.equal(101, bounds[4])
    end)

    it("sets surface_bounds to nil when surface has no data", function ()
      local m = ChunkMap.new()
      m:insert(make_entity(1, 1, 0, 0), make_overlay(1))
      m:remove(1)
      m.max_reach_x = 100
      m.max_reach_y = 50
      m:update_surface_bounds(1)
      assert.is_nil(m.surface_bounds[1])
    end)

    it("clears dirty flag after update", function ()
      local m = ChunkMap.new()
      m:insert(make_entity(1, 1, 0, 0), make_overlay(1))
      m.max_reach_x = 10
      m.max_reach_y = 10
      m:update_surface_bounds(1)
      assert.is_nil(m.surface_bounds_dirty[1])
    end)

    it("updates bounds in-place on second call", function ()
      local m = ChunkMap.new()
      m:insert(make_entity(1, 1, 0, 0), make_overlay(1))
      m.max_reach_x = 10
      m.max_reach_y = 10
      m:update_surface_bounds(1)
      local first_bounds = m.surface_bounds[1]
      m:insert(make_entity(2, 1, 64, 64), make_overlay(2))
      m:update_surface_bounds(1)
      -- same table object mutated in-place
      assert.are.equal(first_bounds, m.surface_bounds[1])
      assert.are.equal(106, m.surface_bounds[1][3])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("update_all_surface_bounds", function ()
    it("updates bounds for all surfaces and clears all dirty flags", function ()
      local m = ChunkMap.new()
      m:insert(make_entity(1, 1, 0, 0), make_overlay(1))
      m:insert(make_entity(2, 2, 0, 0), make_overlay(2))
      m.max_reach_x = 10
      m.max_reach_y = 5
      m:update_all_surface_bounds()
      assert.is_not_nil(m.surface_bounds[1])
      assert.is_not_nil(m.surface_bounds[2])
      assert.is_nil(m.surface_bounds_dirty[1])
      assert.is_nil(m.surface_bounds_dirty[2])
    end)

    it("removes stale bounds for surfaces with no data", function ()
      local m = ChunkMap.new()
      m:insert(make_entity(1, 1, 0, 0), make_overlay(1))
      m.max_reach_x = 10
      m.max_reach_y = 5
      m:update_all_surface_bounds() -- creates surface_bounds[1]
      m:remove(1)                   -- marks dirty, removes data[1]
      m:update_all_surface_bounds() -- should clear surface_bounds[1]
      assert.is_nil(m.surface_bounds[1])
      assert.is_nil(m.surface_bounds_dirty[1])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("zoom_spec_to_zoom", function ()
    it("Method 1: returns zoom field directly", function ()
      assert.are.equal(0.5, ChunkMap.zoom_spec_to_zoom({ zoom = 0.5 }, 1280, 720))
    end)

    it("Method 2: normal wide (16:9) — distance tiles along width", function ()
      -- width=1280, height=720, aspect=16/9, distance=40
      -- zoom = 1280 / (40 * 32) = 1.0
      assert.are.equal(1.0, ChunkMap.zoom_spec_to_zoom({ distance = 40 }, 1280, 720))
    end)

    it("Method 2: normal wide (between 1:1 and 16:9) — distance tiles along width", function ()
      -- width=1000, height=720, aspect≈1.39, distance=25
      -- zoom = 1000 / (25 * 32) = 1.25
      assert.are.equal(1.25, ChunkMap.zoom_spec_to_zoom({ distance = 25 }, 1000, 720))
    end)

    it("Method 2: square (1:1) — distance tiles along width (longer axis = equal)", function ()
      -- width=720, height=720, aspect=1.0, distance=20
      -- zoom = 720 / (20 * 32) = 1.125
      assert.are.equal(1.125, ChunkMap.zoom_spec_to_zoom({ distance = 20 }, 720, 720))
    end)

    it("Method 2: normal portrait (between 1:1 and 9:16) — distance tiles along height", function ()
      -- width=720, height=1000, aspect≈0.72, distance=25
      -- zoom = 1000 / (25 * 32) = 1.25
      assert.are.equal(1.25, ChunkMap.zoom_spec_to_zoom({ distance = 25 }, 720, 1000))
    end)

    it("Method 2: ultra-wide (>16:9) — distance*9/16 tiles along height", function ()
      -- width=2560, height=720, aspect≈3.56, distance=40
      -- zoom = 720 * 16 / (40 * 9 * 32) = 11520 / 11520 = 1.0
      assert.are.equal(1.0, ChunkMap.zoom_spec_to_zoom({ distance = 40 }, 2560, 720))
    end)

    it("Method 2: ultra-portrait (<9:16) — distance*9/16 tiles along height", function ()
      -- width=480, height=1280, aspect=0.375, distance=40
      -- zoom = 1280 * 16 / (40 * 9 * 32) = 20480 / 11520 ≈ 1.778
      local zoom = ChunkMap.zoom_spec_to_zoom({ distance = 40 }, 480, 1280)
      assert.is_true(math.abs(zoom - 1280 * 16 / (40 * 9 * 32)) < 1e-10)
    end)

    it("Method 2: max_distance restricts when it yields a higher zoom", function ()
      -- width=1280, height=720, distance=40 → zoom_from_dist=1.0
      -- max_distance=20 → longer_axis=1280, zoom_from_max=1280/(20*32)=2.0
      -- result = max(1.0, 2.0) = 2.0
      assert.are.equal(2.0, ChunkMap.zoom_spec_to_zoom({ distance = 40, max_distance = 20 }, 1280, 720))
    end)

    it("Method 2: max_distance has no effect when zoom_from_distance is already higher", function ()
      -- zoom_from_dist=2.0, zoom_from_max=1.0 → result=2.0
      assert.are.equal(2.0, ChunkMap.zoom_spec_to_zoom({ distance = 20, max_distance = 40 }, 1280, 720))
    end)

    it("Method 2: default max_distance (500) is large enough not to restrict normal usage", function ()
      -- zoom_from_dist=1.0, zoom_from_max=1280/(500*32)=0.08 → result=1.0
      assert.are.equal(1.0, ChunkMap.zoom_spec_to_zoom({ distance = 40 }, 1280, 720))
    end)
  end)

  -- -------------------------------------------------------------------
  describe("set_furthest_game_view", function ()
    it("computes and caches furthest_zoom", function ()
      local m = ChunkMap.new()
      -- zoom=0.5, width=640, height=480
      m:set_furthest_game_view({ zoom = 0.5 }, 640, 480)
      assert.are.equal(0.5, m.furthest_zoom)
    end)

    it("computes max_reach_x and max_reach_y from zoom and viewport", function ()
      local m = ChunkMap.new()
      -- zoom=0.5, width=640, height=480
      -- max_reach_x = 640 / (0.5 * 64) + 6 = 640/32 + 6 = 20 + 6 = 26
      -- max_reach_y = 480 / (0.5 * 64) + 6 = 480/32 + 6 = 15 + 6 = 21
      m:set_furthest_game_view({ zoom = 0.5 }, 640, 480)
      assert.are.equal(26, m.max_reach_x)
      assert.are.equal(21, m.max_reach_y)
    end)

    it("marks all surfaces dirty when zoom changes", function ()
      local m = ChunkMap.new()
      m:insert(make_entity(1, 1, 0, 0), make_overlay(1))
      m:insert(make_entity(2, 2, 0, 0), make_overlay(2))
      m.surface_bounds_dirty[1] = nil
      m.surface_bounds_dirty[2] = nil
      m:set_furthest_game_view({ zoom = 0.5 }, 640, 480)
      assert.is_true(m.surface_bounds_dirty[1])
      assert.is_true(m.surface_bounds_dirty[2])
    end)

    it("does not mark dirty when zoom is unchanged", function ()
      local m = ChunkMap.new()
      m:insert(make_entity(1, 1, 0, 0), make_overlay(1))
      m:set_furthest_game_view({ zoom = 0.5 }, 640, 480)
      m.surface_bounds_dirty[1] = nil  -- clear dirty
      m:set_furthest_game_view({ zoom = 0.5 }, 640, 480)  -- same zoom
      assert.is_nil(m.surface_bounds_dirty[1])
    end)

    it("updates reach and marks dirty when zoom changes on second call", function ()
      local m = ChunkMap.new()
      m:insert(make_entity(1, 1, 0, 0), make_overlay(1))
      m:set_furthest_game_view({ zoom = 0.5 }, 640, 480)
      m.surface_bounds_dirty[1] = nil  -- clear dirty
      m:set_furthest_game_view({ zoom = 0.25 }, 640, 480)
      -- max_reach_x = 640/(0.25*64)+6 = 640/16+6 = 40+6 = 46
      assert.are.equal(46, m.max_reach_x)
      assert.is_true(m.surface_bounds_dirty[1])
    end)
  end)
end)
