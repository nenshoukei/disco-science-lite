local ColorRegistry = require("scripts.runtime.color-registry")
local LabRegistry = require("scripts.runtime.lab-registry")
local ColorFunctions = require("scripts.runtime.color-functions")
local PlayerViewTracker = require("scripts.runtime.player-view-tracker")
local reset_mocks = require("spec.helper").reset_mocks

--- Rendering mock: draw_animation returns a mock LuaRenderObject.
--- @diagnostic disable-next-line: missing-fields
_G.rendering = {
  objects = {},
  next_id = 1,
  clear = function ()
    _G.rendering.objects = {}
  end,
  get_all_objects = function (mod_name)
    local objects = {}
    for _, obj in pairs(_G.rendering.objects) do
      objects[#objects + 1] = obj
    end
    return objects
  end,
  draw_animation = function (params)
    local id = _G.rendering.next_id
    _G.rendering.next_id = id + 1
    --- destroy() is called without self (dot notation), so use a closure.
    local obj = {
      id               = id,
      valid            = true,
      visible          = false,
      color            = { 0, 0, 0 },
      surface          = params.surface,
      target           = { entity = params.target },
      animation        = params.animation,
      x_scale          = params.x_scale,
      y_scale          = params.y_scale,
      animation_offset = params.animation_offset,
    }
    obj.destroy = function ()
      obj.valid = false
      _G.rendering.objects[id] = nil
    end
    _G.rendering.objects[id] = obj
    return obj --[[@as LuaRenderObject]]
  end,
}

local LabOverlayRenderer = require("scripts.runtime.lab-overlay-renderer")

-- -----------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------

--- Build a mock LuaTechnology
--- @param ingredients string[]? Names of research_unit_ingredients
--- @return LuaTechnology
local function make_tech(ingredients)
  local research_unit_ingredients = {}
  if ingredients then
    for i = 1, #ingredients do
      research_unit_ingredients[i] = { name = ingredients[i] }
    end
  end
  return ({ research_unit_ingredients = research_unit_ingredients }) --[[@as LuaTechnology]]
end

--- Build a mock LuaForce.
--- @param index number
--- @return LuaForce
local function make_force(index)
  return ({ index = index, current_research = make_tech() }) --[[@as LuaForce]]
end

--- Build a mock LuaEntity representing a lab on a given surface.
--- @param unit_number number
--- @param surface_index number
--- @param x number
--- @param y number
--- @param force_index number?
--- @return LuaEntity
local function make_entity(unit_number, surface_index, x, y, force_index)
  x = x or 0
  y = y or 0
  return ({
    valid         = true,
    type          = "lab",
    unit_number   = unit_number,
    surface_index = surface_index,
    force_index   = force_index or 1,
    name          = "lab",
    position      = { x = x, y = y },
    tile_width    = 3,
    tile_height   = 3,
    prototype     = { tile_width = 3, tile_height = 3 },
    surface       = ({ index = surface_index }) --[[@as LuaSurface]],
    status        = defines.entity_status.working,
  }) --[[@as LuaEntity]]
end

--- Build a minimal LabOverlay for tests that bypass render_overlay_for_lab.
--- @param unit_number number
--- @param surface_index number?
--- @param x number?
--- @param y number?
--- @param force_index number?
--- @return LabOverlay
local function make_overlay(unit_number, surface_index, x, y, force_index)
  x = x or 0
  y = y or 0
  surface_index = surface_index or 1
  force_index = force_index or 1
  local entity = make_entity(unit_number, surface_index, x, y, force_index)
  local anim = { valid = true, visible = false, color = { 0, 0, 0 } }
  anim.destroy = function () anim.valid = false end
  return {
    entity,                         -- OV_ENTITY
    anim --[[@as LuaRenderObject]], -- OV_ANIMATION
    x,                              -- OV_X
    y,                              -- OV_Y
    { x, y, x + 3, y + 3 },         -- OV_RECT
    false,                          -- OV_VISIBLE
    unit_number,                    -- OV_UNIT_NUM
    force_index,                    -- OV_FORCE_INDEX
  }
end

--- Build a LabOverlayRenderer with empty registries.
--- @return LabOverlayRenderer
local function make_renderer()
  return LabOverlayRenderer.new(ColorRegistry.new(), LabRegistry.new())
end

--- Add a player tracker with an active view to the renderer.
--- @param renderer LabOverlayRenderer
--- @param surface_index number
--- @param force LuaForce
--- @param chunk_left number?
--- @param chunk_top number?
--- @param chunk_right number?
--- @param chunk_bottom number?
--- @param player_index number?
--- @return PlayerViewTracker
local function activate_view(renderer, surface_index, force, chunk_left, chunk_top, chunk_right, chunk_bottom,
                             player_index)
  player_index = player_index or 1
  local tracker = PlayerViewTracker.new()
  local view = tracker.view
  view[ 1 --[[$PV_VALID]] ] = true
  view[ 2 --[[$PV_SURFACE]] ] = surface_index
  view[ 3 --[[$PV_LEFT]] ] = chunk_left or -10
  view[ 4 --[[$PV_TOP]] ] = chunk_top or -10
  view[ 5 --[[$PV_RIGHT]] ] = chunk_right or 10
  view[ 6 --[[$PV_BOTTOM]] ] = chunk_bottom or 10
  tracker.force = force
  renderer.player_trackers[player_index] = tracker
  return tracker
end

-- -----------------------------------------------------------------------
-- Tests
-- -----------------------------------------------------------------------

describe("LabOverlayRenderer", function ()
  before_each(function ()
    reset_mocks()
    _G.rendering.objects = {}
    _G.rendering.next_id = 1
  end)

  -- -------------------------------------------------------------------
  describe("new", function ()
    it("starts with empty data structures", function ()
      local r = make_renderer()
      assert.are.same({}, r.overlays)
      assert.are.same({}, r.visible_overlays)
      assert.are.same({}, r.force_state)
      assert.are.same({}, r.player_trackers)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("load_settings", function ()
    it("updates instance variables from global settings", function ()
      local r = make_renderer()

      _G.settings.startup[ "mks-dsl-fallback-overlay-enabled" --[[$FALLBACK_OVERLAY_ENABLED_NAME]] ].value = false
      _G.settings.global[ "mks-dsl-unison-flicker" --[[$UNISON_FLICKER_NAME]] ].value = true
      _G.settings.global[ "mks-dsl-color-intensity" --[[$COLOR_INTENSITY_NAME]] ].value = 50
      _G.settings.global[ "mks-dsl-color-pattern-duration" --[[$COLOR_PATTERN_DURATION_NAME]] ].value = 120
      _G.settings.global[ "mks-dsl-max-updates-per-tick" --[[$MAX_UPDATES_PER_TICK_NAME]] ].value = 500

      r:load_settings()

      assert.is_false(r.is_fallback_enabled)
      assert.is_true(r.is_unison_flicker)
      assert.are.equal(0.5, r.color_intensity)
      assert.are.equal(120, r.color_pattern_duration)
      assert.are.equal(500, r.max_updates_per_tick)
    end)

    it("calls side effects when unison-flicker or color-intensity changes", function ()
      local r = make_renderer()

      local flicker_called = false
      local research_called = false
      r.reset_all_overlays_animation_offset = function () flicker_called = true end
      r.update_all_forces_current_research = function () research_called = true end

      _G.settings.global[ "mks-dsl-unison-flicker" --[[$UNISON_FLICKER_NAME]] ].value = not r.is_unison_flicker
      _G.settings.global[ "mks-dsl-color-intensity" --[[$COLOR_INTENSITY_NAME]] ].value = 50
      r:load_settings()

      assert.is_true(flicker_called)
      assert.is_true(research_called)
    end)

    it("does not call side effects when game is nil (on_load safety)", function ()
      local old_game = _G.game
      _G.game = nil

      local r = make_renderer()
      local flicker_called = false
      local research_called = false
      r.reset_all_overlays_animation_offset = function () flicker_called = true end
      r.update_all_forces_current_research = function () research_called = true end

      _G.settings.global[ "mks-dsl-unison-flicker" --[[$UNISON_FLICKER_NAME]] ].value = not r.is_unison_flicker
      r:load_settings()

      assert.is_false(flicker_called)
      assert.is_false(research_called)

      _G.game = old_game
    end)
  end)

  -- -------------------------------------------------------------------
  describe("render_overlay_for_lab", function ()
    it("returns nil when lab has no unit_number", function ()
      local r = make_renderer()
      local lab = make_entity(1, 1, 0, 0)
      lab.unit_number = nil
      assert.is_nil(r:render_overlay_for_lab(lab))
    end)

    it("returns nil when no overlay settings registered and fallback disabled", function ()
      local r = make_renderer()
      r.is_fallback_enabled = false
      -- lab_registry has no registration for "lab"
      local result = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_nil(result)
    end)

    it("creates and returns an overlay with correct initial values", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { animation = "lab-anim", scale = 1.5 })
      local ov = r:render_overlay_for_lab(make_entity(77, 1, 0, 0, 3))

      assert.is_not_nil(ov) --- @cast ov -nil
      assert.are.equal(77, ov[ 7 --[[$OV_UNIT_NUM]] ])
      assert.are.equal(3, ov[ 8 --[[$OV_FORCE_INDEX]] ])
      assert.is_false(ov[ 6 --[[$OV_VISIBLE]] ])
      assert.are.equal("lab-anim", ov[ 2 --[[$OV_ANIMATION]] ].animation)
      assert.are.equal(1.5, ov[ 2 --[[$OV_ANIMATION]] ].x_scale)
    end)

    it("creates overlay using fallback when no settings registered but fallback enabled", function ()
      local r = make_renderer()
      r.is_fallback_enabled = true
      -- lab_registry has no registration for "lab"
      local overlay = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_not_nil(overlay)
    end)

    it("stores and indexes the new overlay", function ()
      local r = make_renderer()
      r:render_overlay_for_lab(make_entity(42, 1, 0, 0))
      assert.is_not_nil(r.overlays[42])
      assert.is_not_nil(r.chunk_map.entries[42])
    end)

    it("always creates a new animation object", function ()
      local r = make_renderer()
      local lab = make_entity(1, 1, 0, 0)
      local ov1 = r:render_overlay_for_lab(lab)
      local ov2 = r:render_overlay_for_lab(lab)
      assert.is_not_nil(ov1) --- @cast ov1 -nil
      assert.is_not_nil(ov2) --- @cast ov2 -nil
      assert.are_not.equal(ov1[ 2 --[[$OV_ANIMATION]] ], ov2[ 2 --[[$OV_ANIMATION]] ])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("render_overlays_for_all_labs", function ()
    it("reuses existing render objects", function ()
      local r = make_renderer()
      local lab = make_entity(1, 1, 0, 0)
      _G.game.surfaces = { [1] = lab.surface }
      lab.surface.find_entities_filtered = function () return { lab } end

      -- Initial render
      r:render_overlays_for_all_labs()
      local anim1_id = r.overlays[1][ 2 --[[$OV_ANIMATION]] ].id

      -- Second render (rebuild)
      r:render_overlays_for_all_labs()
      assert.are.equal(anim1_id, r.overlays[1][ 2 --[[$OV_ANIMATION]] ].id)
    end)

    it("destroys orphaned or removed labs' render objects", function ()
      local r = make_renderer()
      local lab1 = make_entity(1, 1, 0, 0)
      local lab2 = make_entity(2, 1, 32, 0)
      _G.game.surfaces = { [1] = lab1.surface }

      -- Initially two labs and one orphan
      local orphan = _G.rendering.draw_animation({
        animation = "lab-anim",
        surface = lab1.surface,
        target = { entity = ({ valid = false }) --[[@as LuaEntity]] },
      })
      local orphan_id = orphan.id
      --- @diagnostic disable-next-line: duplicate-set-field
      lab1.surface.find_entities_filtered = function () return { lab1, lab2 } end
      r:render_overlays_for_all_labs()
      local anim2_id = r.overlays[2][ 2 --[[$OV_ANIMATION]] ].id

      -- Rebuild with only lab1 remaining
      --- @diagnostic disable-next-line: duplicate-set-field
      lab1.surface.find_entities_filtered = function () return { lab1 } end
      r:render_overlays_for_all_labs()

      assert.is_nil(_G.rendering.objects[orphan_id])
      assert.is_nil(_G.rendering.objects[anim2_id])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("reset_all_overlays_animation_offset", function ()
    it("updates animation_offset based on is_unison_flicker", function ()
      local r = make_renderer()
      local obj1 = { animation_offset = 123 }
      local obj2 = { animation_offset = 456 }
      _G.rendering.objects = { [1] = obj1, [2] = obj2 }

      r.is_unison_flicker = true
      r:reset_all_overlays_animation_offset()
      assert.are.equal(0, obj1.animation_offset)
      assert.are.equal(0, obj2.animation_offset)

      r.is_unison_flicker = false
      r:reset_all_overlays_animation_offset()
      assert.is_true(obj1.animation_offset > 0)
      assert.is_true(obj1.animation_offset <= 300)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("remove_overlay_from_lab", function ()
    it("removes overlay from data structures and destroys animation", function ()
      local r = make_renderer()
      local ov = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_not_nil(ov) --- @cast ov -nil
      local anim = ov[ 2 --[[$OV_ANIMATION]] ]
      r.visible_overlays[1] = ov

      r:remove_overlay_from_lab(1)

      assert.is_nil(r.overlays[1])
      assert.is_nil(r.chunk_map.entries[1])
      assert.is_false(anim.valid)
      assert.are.equal(0, #r.visible_overlays)
    end)

    it("does not error for unknown unit_number or invalid animation", function ()
      local r = make_renderer()
      local ov = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_not_nil(ov) --- @cast ov -nil
      ov[ 2 --[[$OV_ANIMATION]] ].valid = false

      assert.no_error(function ()
        r:remove_overlay_from_lab(999)
        r:remove_overlay_from_lab(1)
      end)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("remove_overlays_on_surface", function ()
    it("removes all overlays on the target surface only", function ()
      local r = make_renderer()
      local anim1 = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))[ 2 --[[$OV_ANIMATION]] ]
      local anim2 = r:render_overlay_for_lab(make_entity(2, 2, 0, 0))[ 2 --[[$OV_ANIMATION]] ]

      r:remove_overlays_on_surface(2)

      assert.is_not_nil(r.overlays[1])
      assert.is_true(anim1.valid)
      assert.is_nil(r.overlays[2])
      assert.is_false(anim2.valid)
      assert.is_nil(r.chunk_map.data[2])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("update_lab_position", function ()
    it("updates position and OV_RECT on the same surface", function ()
      local r = make_renderer()
      local lab = make_entity(1, 1, 0, 0)
      r:render_overlay_for_lab(lab)

      lab.position = { x = 32, y = 32 }
      r:update_lab_position(lab)

      local ov = r.overlays[1]
      assert.are.equal(32, ov[ 3 --[[$OV_X]] ])
      assert.are.equal(32, ov[ 5 --[[$OV_RECT]] ][1])
      assert.are.equal(lab, ov[ 2 --[[$OV_ANIMATION]] ].target)
    end)

    it("rebuilds overlay when lab teleports to another surface", function ()
      local r = make_renderer()
      local lab = make_entity(1, 1, 0, 0)
      r:render_overlay_for_lab(lab)
      local old_anim = r.overlays[1][ 2 --[[$OV_ANIMATION]] ]

      lab.surface_index = 2
      lab.surface = ({ index = 2 }) --[[@as LuaSurface]]
      r:update_lab_position(lab)

      assert.is_false(old_anim.valid)
      assert.are.equal(2, r.overlays[1][ 2 --[[$OV_ANIMATION]] ].surface.index)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("remove_player_tracker", function ()
    it("removes the tracker for the given player index", function ()
      local r = make_renderer()
      r.player_trackers[1] = PlayerViewTracker.new()
      r:remove_player_tracker(1)
      assert.is_nil(r.player_trackers[1])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("get_tracker_update_function", function ()
    it("creates trackers and updates force_state positions", function ()
      local r = make_renderer()
      r.force_state[1] = { nil, nil, 0, 0, 0 }

      local player1 = ({
        index = 1,
        force = { index = 1 },
        position = { x = 10, y = 20 },
        surface_index = 1,
        render_mode = defines.render_mode.game,
        zoom = 1,
        display_resolution = { width = 1920, height = 1080 },
      }) --[[@as LuaPlayer]]
      _G.game.forces = { player = { index = 1, connected_players = { player1 } } }

      r:get_tracker_update_function()()

      assert.is_not_nil(r.player_trackers[1])
      assert.are.equal(10, r.force_state[1][ 4 --[[$FS_PX]] ])
      assert.are.equal(20, r.force_state[1][ 5 --[[$FS_PY]] ])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("update_force_current_research", function ()
    it("updates research and flattens colors in force_state", function ()
      local r = make_renderer()
      local force = make_force(1)
      local tech = make_tech({ "automation-science-pack", "logistic-science-pack" })
      force.current_research = tech

      r.force_state[1] = { nil, nil, 0, 10, 20 }
      r.color_registry:set_ingredient_color("automation-science-pack", { 1, 0, 0 })
      r.color_registry:set_ingredient_color("logistic-science-pack", { 0, 1, 0 })
      r.color_intensity = 1.0

      r:update_force_current_research(force)

      local fs = r.force_state[1]
      assert.is_not_nil(fs) --- @cast fs -nil
      assert.are.equal(tech, fs[ 1 --[[$FS_CURRENT_RESEARCH]] ])
      assert.are.same({ 1, 0, 0, 0, 1, 0 }, fs[ 2 --[[$FS_COLORS]] ])
      assert.are.equal(2, fs[ 3 --[[$FS_N_COLORS]] ])
      assert.are.equal(10, fs[ 4 --[[$FS_PX]] ]) -- preserved
    end)

    it("clears colors when research is nil", function ()
      local r = make_renderer()
      local force = make_force(1)
      force.current_research = nil
      r.force_state[1] = { nil, { 1, 1, 1 }, 1, 0, 0 }

      r:update_force_current_research(force)

      assert.is_nil(r.force_state[1][ 2 --[[$FS_COLORS]] ])
      assert.are.equal(0, r.force_state[1][ 3 --[[$FS_N_COLORS]] ])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("update_all_forces_current_research", function ()
    it("updates each force in self.force_state", function ()
      local r = make_renderer()
      _G.game.forces = { [1] = make_force(1), [2] = make_force(2) }
      r.force_state[1] = { nil, nil, 0, 0, 0 }
      r.force_state[2] = { nil, nil, 0, 0, 0 }

      local update_calls = 0
      r.update_force_current_research = function () update_calls = update_calls + 1 end

      r:update_all_forces_current_research()
      assert.are.equal(2, update_calls)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("get_state_update_function", function ()
    it("populates visible_overlays and updates visibility based on status and research", function ()
      local r = make_renderer()
      local force = make_force(1)

      local lab_working = make_entity(1, 1, 0, 0)
      local ov_working = r:render_overlay_for_lab(lab_working)
      local lab_normal = make_entity(2, 1, 0, 0)
      lab_normal.status = defines.entity_status.normal
      local ov_normal = r:render_overlay_for_lab(lab_normal)

      activate_view(r, 1, force, -1, -1, 1, 1)
      r:get_state_update_function()()

      assert.is_not_nil(ov_working) --- @cast ov_working -nil
      assert.is_not_nil(ov_normal)  --- @cast ov_normal -nil
      assert.are.equal(1, #r.visible_overlays)
      assert.is_true(ov_working[ 6 --[[$OV_VISIBLE]] ])
      assert.is_false(ov_normal[ 6 --[[$OV_VISIBLE]] ])
    end)

    it("manages force_state and research changes", function ()
      local r = make_renderer()
      local force = make_force(1)
      local tech = make_tech({ "automation-science-pack" })
      force.current_research = tech
      r.color_registry:set_ingredient_color("automation-science-pack", { 1, 1, 1 })

      local tracker = activate_view(r, 1, force, -1, -1, 1, 1)
      tracker.position = { 10, 20 }

      local update = r:get_state_update_function()
      update()

      local fs = r.force_state[1]
      assert.is_not_nil(fs) --- @cast fs -nil
      assert.are.equal(tech, fs[ 1 --[[$FS_CURRENT_RESEARCH]] ])
      assert.are.equal(10, fs[ 4 --[[$FS_PX]] ])

      force.current_research = nil
      update()
      assert.is_nil(fs[ 1 --[[$FS_CURRENT_RESEARCH]] ])
      assert.are.equal(0, fs[ 3 --[[$FS_N_COLORS]] ])
    end)

    it("deduplicates overlays visible to multiple players and clears trailing entries", function ()
      local r = make_renderer()
      local force = make_force(1)
      r:render_overlay_for_lab(make_entity(1, 1, 0, 0))

      -- Stale entry
      r.visible_overlays[1] = make_overlay(99, 1, 0, 0)

      activate_view(r, 1, force, -1, -1, 1, 1, 1)
      activate_view(r, 1, force, -1, -1, 1, 1, 2)

      r:get_state_update_function()()

      assert.are.equal(1, #r.visible_overlays)
      assert.is_nil(r.visible_overlays[2])
    end)

    it("sets current_interval to 1 when visible labs fit within max_updates_per_tick", function ()
      local r = make_renderer()
      local force = make_force(1)
      r.max_updates_per_tick = 200
      for i = 1, 10 do
        r:render_overlay_for_lab(make_entity(i, 1, 0, 0))
      end
      activate_view(r, 1, force, -100, -100, 100, 100)

      r:get_state_update_function()()

      assert.are.equal(1, r.current_interval)
    end)

    it("increases current_interval when visible labs exceed max_updates_per_tick", function ()
      local r = make_renderer()
      local force = make_force(1)
      r.max_updates_per_tick = 10
      for i = 1, 30 do
        r:render_overlay_for_lab(make_entity(i, 1, 0, 0))
      end
      activate_view(r, 1, force, -100, -100, 100, 100)

      r:get_state_update_function()()

      -- ceil(30 / 10) = 3
      assert.are.equal(3, r.current_interval)
    end)

    it("caps current_interval at 60", function ()
      local r = make_renderer()
      local force = make_force(1)
      r.max_updates_per_tick = 1
      for i = 1, 300 do
        r:render_overlay_for_lab(make_entity(i, 1, 0, 0))
      end
      activate_view(r, 1, force, -100, -100, 100, 100)

      r:get_state_update_function()()

      assert.are.equal(60, r.current_interval)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("get_tick_function", function ()
    it("updates animation.color for visible overlays", function ()
      local r = make_renderer()
      r.current_interval = 1
      r.force_state[1] = { make_tech(), { 1.0, 0.0, 0.5 }, 1, 0, 0 }

      local written = false
      local mock_anim = setmetatable({}, {
        __index = { valid = true, visible = true },
        __newindex = function (t, k, v)
          if k == "color" then written = true end
          rawset(t, k, v)
        end,
      })
      local ov = make_overlay(1, 1, 0, 0, 1)
      ov[ 2 --[[$OV_ANIMATION]] ] = mock_anim --[[@as LuaRenderObject]]
      r.visible_overlays[1] = ov

      r:get_tick_function()()
      assert.is_true(written)
    end)

    it("uses stride: updates only 1/N overlays per tick when current_interval=N", function ()
      local r = make_renderer()
      r.current_interval = 3
      r.force_state[1] = { make_tech(), { 1.0, 0.0, 0.5 }, 1, 0, 0 }

      local colored = {}
      for i = 1, 3 do
        local idx = i
        local anim = setmetatable({}, {
          __index = { valid = true, visible = true },
          __newindex = function (t, k, v)
            if k == "color" then colored[#colored + 1] = idx end
            rawset(t, k, v)
          end,
        })
        local ov = make_overlay(i, 1, 0, 0, 1)
        ov[ 2 --[[$OV_ANIMATION]] ] = anim --[[@as LuaRenderObject]]
        r.visible_overlays[i] = ov
      end

      local tick = r:get_tick_function()
      tick()
      assert.are.equal(1, #colored)
      assert.are.equal(2, colored[1])

      tick()
      tick()
      table.sort(colored)
      assert.are.same({ 1, 2, 3 }, colored)
    end)

    -- -------------------------------------------------------------------
    describe("color_pattern_duration", function ()
      local original_choose_random = ColorFunctions.choose_random
      local cf_calls = 0

      before_each(function ()
        cf_calls = 0
        ColorFunctions.choose_random = function (idx)
          cf_calls = cf_calls + 1
          return original_choose_random(idx)
        end
      end)

      after_each(function ()
        ColorFunctions.choose_random = original_choose_random
      end)

      it("switches color function when duration is reached", function ()
        local r = make_renderer()
        r.color_pattern_duration = 3
        r.force_state[1] = { make_tech(), { 1.0, 0.0, 0.0 }, 1, 0, 0 }
        r.visible_overlays[1] = make_overlay(1, 1, 0, 0, 1)

        local tick = r:get_tick_function() -- cf_calls = 1
        tick()                             -- 1
        tick()                             -- 2
        tick()                             -- 3 >= 3, switch!
        assert.are.equal(2, cf_calls)
      end)
    end)
  end)
end)
