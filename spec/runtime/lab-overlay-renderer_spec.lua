local ColorRegistry = require("scripts.runtime.color-registry")
local LabRegistry = require("scripts.runtime.lab-registry")
local ColorFunctions = require("scripts.runtime.color-functions")
local reset_mocks = require("spec.helper").reset_mocks

--- Rendering mock: draw_animation returns a mock LuaRenderObject.
--- @diagnostic disable-next-line: missing-fields
_G.rendering = {
  clear          = function () end,
  draw_animation = function (params)
    --- destroy() is called without self (dot notation), so use a closure.
    local obj = {
      valid   = true,
      visible = false,
      color   = { 0, 0, 0 },
      surface = params.surface,
      target  = params.target,
    }
    obj.destroy = function () obj.valid = false end
    return obj --[[@as LuaRenderObject]]
  end,
}

local LabOverlayRenderer = require("scripts.runtime.lab-overlay-renderer")

-- -----------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------

--- Build a mock LuaForce.
--- @param index number
--- @return LuaForce
local function make_force(index)
  return ({ index = index }) --[[@as LuaForce]]
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
--- @return LabOverlay
local function make_overlay(unit_number, surface_index, x, y)
  x = x or 0
  y = y or 0
  surface_index = surface_index or 1
  local entity = make_entity(unit_number, surface_index, x, y)
  local anim = { valid = true, visible = false, color = { 0, 0, 0 } }
  anim.destroy = function () anim.valid = false end
  return ({
    [ 1 --[[$OV_ENTITY]] ]    = entity,
    [ 2 --[[$OV_ANIMATION]] ] = anim --[[@as LuaRenderObject]],
    [ 3 --[[$OV_X]] ]         = x,
    [ 4 --[[$OV_Y]] ]         = y,
    [ 5 --[[$OV_RECT]] ]      = { x, y, x + 3, y + 3 },
    [ 6 --[[$OV_VISIBLE]] ]   = false,
    [ 7 --[[$OV_UNIT_NUM]] ]  = unit_number,
  }) --[[@as LabOverlay]]
end

--- Build a LabOverlayRenderer with empty registries.
--- @return LabOverlayRenderer
local function make_renderer()
  return LabOverlayRenderer.new(ColorRegistry.new(), LabRegistry.new())
end

--- Activate the player view in the renderer's player_tracker directly.
--- @param renderer LabOverlayRenderer
--- @param surface_index number
--- @param force LuaForce
--- @param chunk_left number?
--- @param chunk_top number?
--- @param chunk_right number?
--- @param chunk_bottom number?
local function activate_view(renderer, surface_index, force, chunk_left, chunk_top, chunk_right, chunk_bottom)
  local view = renderer.player_tracker.view
  view[ 1 --[[$PV_VALID]] ] = true
  view[ 2 --[[$PV_SURFACE]] ] = surface_index
  view[ 3 --[[$PV_LEFT]] ] = chunk_left or -10
  view[ 4 --[[$PV_TOP]] ] = chunk_top or -10
  view[ 5 --[[$PV_RIGHT]] ] = chunk_right or 10
  view[ 6 --[[$PV_BOTTOM]] ] = chunk_bottom or 10
  renderer.player_tracker.force = force
end

-- -----------------------------------------------------------------------
-- Tests
-- -----------------------------------------------------------------------

describe("LabOverlayRenderer", function ()
  before_each(function ()
    reset_mocks()
  end)

  -- -------------------------------------------------------------------
  describe("new", function ()
    it("starts with empty overlays", function ()
      local r = make_renderer()
      assert.are.same({}, r.overlays)
    end)

    it("starts with empty visible_overlays", function ()
      local r = make_renderer()
      assert.are.same({}, r.visible_overlays)
    end)

    it("starts with nil current_research", function ()
      local r = make_renderer()
      assert.is_nil(r.current_research)
    end)

    it("starts with nil current_research_colors", function ()
      local r = make_renderer()
      assert.is_nil(r.current_research_colors)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("render_overlay_for_lab", function ()
    it("returns nil when lab.valid is false", function ()
      local r = make_renderer()
      local lab = make_entity(1, 1, 0, 0)
      lab.valid = false
      assert.is_nil(r:render_overlay_for_lab(lab))
    end)

    it("returns nil when entity type is not 'lab'", function ()
      local r = make_renderer()
      local lab = make_entity(1, 1, 0, 0)
      lab.type = "assembling-machine"
      assert.is_nil(r:render_overlay_for_lab(lab))
    end)

    it("returns nil when lab has no unit_number", function ()
      local r = make_renderer()
      local lab = make_entity(1, 1, 0, 0)
      lab.unit_number = nil
      assert.is_nil(r:render_overlay_for_lab(lab))
    end)

    it("returns nil when player_tracker has no force", function ()
      local r = make_renderer()
      -- player_tracker.force is nil by default
      assert.is_nil(r:render_overlay_for_lab(make_entity(1, 1, 0, 0)))
    end)

    it("returns nil when lab force_index does not match player force", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      local lab = make_entity(1, 1, 0, 0, 2) -- force_index 2 != player force 1
      assert.is_nil(r:render_overlay_for_lab(lab))
    end)

    it("returns nil when no overlay settings registered and fallback disabled", function ()
      _G.settings.startup[ "mks-dsl-fallback-overlay-enabled" --[[$FALLBACK_OVERLAY_ENABLED_NAME]] ].value = false
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      -- lab_registry has no registration for "lab"
      local result = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_nil(result)
    end)

    it("creates and returns an overlay when overlay_settings are registered", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      r.lab_registry:register("lab", { animation = "lab-anim", scale = 1 })
      local overlay = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_not_nil(overlay)
    end)

    it("creates overlay using fallback when no settings registered but fallback enabled", function ()
      _G.settings.startup[ "mks-dsl-fallback-overlay-enabled" --[[$FALLBACK_OVERLAY_ENABLED_NAME]] ].value = true
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      -- lab_registry has no registration for "lab"
      local overlay = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_not_nil(overlay)
    end)

    it("stores the new overlay in self.overlays keyed by unit_number", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      r:render_overlay_for_lab(make_entity(42, 1, 0, 0))
      assert.is_not_nil(r.overlays[42])
    end)

    it("inserts overlay into chunk_map", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_not_nil(r.chunk_map.entries[1])
    end)

    it("overlay[OV_UNIT_NUM] matches lab unit_number", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      local ov = r:render_overlay_for_lab(make_entity(77, 1, 0, 0))
      assert.is_not_nil(ov) --- @cast ov -nil
      assert.are.equal(77, ov[ 7 --[[$OV_UNIT_NUM]] ])
    end)

    it("overlay starts with visible=false", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      local ov = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_not_nil(ov) --- @cast ov -nil
      assert.is_false(ov[ 6 --[[$OV_VISIBLE]] ])
    end)

    it("returns existing overlay without re-rendering when force_render is false", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      local lab = make_entity(1, 1, 0, 0)
      local ov1 = r:render_overlay_for_lab(lab)
      local ov2 = r:render_overlay_for_lab(lab, false)
      assert.are.equal(ov1, ov2)
    end)

    it("creates a new overlay when force_render is true", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      local lab = make_entity(1, 1, 0, 0)
      local ov1 = r:render_overlay_for_lab(lab)
      local ov2 = r:render_overlay_for_lab(lab, true)
      assert.is_not_nil(ov1) --- @cast ov1 -nil
      assert.is_not_nil(ov2) --- @cast ov2 -nil
      -- New overlay means a new animation object
      assert.are_not.equal(ov1[ 2 --[[$OV_ANIMATION]] ], ov2[ 2 --[[$OV_ANIMATION]] ])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("remove_overlay_from_lab", function ()
    it("does nothing for unknown unit_number", function ()
      local r = make_renderer()
      assert.no_error(function () r:remove_overlay_from_lab(999) end)
    end)

    it("removes overlay from self.overlays", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      r:remove_overlay_from_lab(1)
      assert.is_nil(r.overlays[1])
    end)

    it("removes overlay from chunk_map", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      r:remove_overlay_from_lab(1)
      assert.is_nil(r.chunk_map.entries[1])
    end)

    it("destroys the animation render object", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      local ov = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_not_nil(ov) --- @cast ov -nil
      local anim = ov[ 2 --[[$OV_ANIMATION]] ]
      r:remove_overlay_from_lab(1)
      assert.is_false(anim.valid)
    end)

    it("does not error when animation is already invalid", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      local ov = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_not_nil(ov) --- @cast ov -nil
      -- pre-invalidate
      ov[ 2 --[[$OV_ANIMATION]] ].valid = false
      assert.no_error(function () r:remove_overlay_from_lab(1) end)
    end)

    it("removes overlay from visible_overlays", function ()
      local r = make_renderer()
      local ov = make_overlay(10, 1, 0, 0)
      r.overlays[10] = ov
      r.visible_overlays[1] = ov
      r:remove_overlay_from_lab(10)
      for i = 1, #r.visible_overlays do
        assert.are_not.equal(ov, r.visible_overlays[i])
      end
    end)
  end)

  -- -------------------------------------------------------------------
  describe("remove_overlays_on_surface", function ()
    it("does nothing when surface has no data", function ()
      local r = make_renderer()
      assert.no_error(function () r:remove_overlays_on_surface(999) end)
    end)

    it("removes all overlays on the surface from self.overlays", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      r:render_overlay_for_lab(make_entity(1, 2, 0, 0))
      r:render_overlay_for_lab(make_entity(2, 2, 32, 0))
      r:remove_overlays_on_surface(2)
      assert.is_nil(r.overlays[1])
      assert.is_nil(r.overlays[2])
    end)

    it("destroys valid animations on the surface", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      local ov = r:render_overlay_for_lab(make_entity(1, 2, 0, 0))
      assert.is_not_nil(ov) --- @cast ov -nil
      local anim = ov[ 2 --[[$OV_ANIMATION]] ]
      r:remove_overlays_on_surface(2)
      assert.is_false(anim.valid)
    end)

    it("clears surface data from chunk_map.data", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      r:render_overlay_for_lab(make_entity(1, 3, 0, 0))
      r:remove_overlays_on_surface(3)
      assert.is_nil(r.chunk_map.data[3])
    end)

    it("does not remove overlays on other surfaces", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      r:render_overlay_for_lab(make_entity(2, 2, 0, 0))
      r:remove_overlays_on_surface(2)
      assert.is_not_nil(r.overlays[1]) -- surface 1 untouched
    end)
  end)

  -- -------------------------------------------------------------------
  describe("update_lab_position", function ()
    it("does nothing when lab has no unit_number", function ()
      local r = make_renderer()
      local lab = make_entity(1, 1, 0, 0)
      lab.unit_number = nil
      assert.no_error(function () r:update_lab_position(lab) end)
    end)

    it("does nothing when no overlay exists for the lab", function ()
      local r = make_renderer()
      assert.no_error(function () r:update_lab_position(make_entity(1, 1, 0, 0)) end)
    end)

    it("updates OV_RECT when position changes on the same surface", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      local lab = make_entity(1, 1, 0, 0)
      r:render_overlay_for_lab(lab)

      lab.position = { x = 32, y = 32 }
      r:update_lab_position(lab)

      local ov = r.overlays[1]
      assert.is_not_nil(ov) --- @cast ov -nil
      assert.are.equal(32, ov[ 5 --[[$OV_RECT]] ][1])
    end)

    it("updates animation.target on the same surface", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      local lab = make_entity(1, 1, 0, 0)
      r:render_overlay_for_lab(lab)
      local ov = r.overlays[1]
      assert.is_not_nil(ov) --- @cast ov -nil

      lab.position = { x = 32, y = 32 }
      r:update_lab_position(lab)

      assert.are.equal(lab, ov[ 2 --[[$OV_ANIMATION]] ].target)
    end)

    it("destroys old animation and creates new overlay when lab teleports to another surface", function ()
      local r = make_renderer()
      r.player_tracker.force = make_force(1)
      local lab = make_entity(1, 1, 0, 0)
      r:render_overlay_for_lab(lab)
      local old_anim = r.overlays[1][ 2 --[[$OV_ANIMATION]] ]

      -- Simulate teleport to surface 2
      lab.surface_index = 2
      lab.surface = ({ index = 2 }) --[[@as LuaSurface]]
      -- old_anim.surface.index is still 1 (the surface mock set at render time)
      r:update_lab_position(lab)

      assert.is_false(old_anim.valid)  -- old animation destroyed
      assert.is_not_nil(r.overlays[1]) -- new overlay created
    end)
  end)

  -- -------------------------------------------------------------------
  describe("update_overlay_states", function ()
    it("does nothing when view is invalid", function ()
      local r = make_renderer()
      -- player_tracker.view[PV_VALID] is false by default
      assert.no_error(function () r:update_overlay_states() end)
      assert.are.same({}, r.visible_overlays)
    end)

    it("populates visible_overlays with working labs in the view range", function ()
      local r = make_renderer()
      local force = make_force(1)
      force.current_research = ({ research_unit_ingredients = {} }) --[[@as LuaTechnology]]

      r.player_tracker.force = force
      local lab = make_entity(1, 1, 0, 0)
      lab.status = defines.entity_status.working
      r:render_overlay_for_lab(lab)

      activate_view(r, 1, force, -1, -1, 1, 1)
      r:update_overlay_states()

      assert.are.equal(1, #r.visible_overlays)
    end)

    it("sets OV_VISIBLE and animation.visible=true when entity is working and research is active", function ()
      local r = make_renderer()
      local force = make_force(1)
      force.current_research = ({ research_unit_ingredients = {} }) --[[@as LuaTechnology]]

      r.player_tracker.force = force
      local lab = make_entity(1, 1, 0, 0)
      lab.status = defines.entity_status.working
      local ov = r:render_overlay_for_lab(lab)
      assert.is_not_nil(ov) --- @cast ov -nil

      activate_view(r, 1, force, -1, -1, 1, 1)
      r:update_overlay_states()

      assert.is_true(ov[ 6 --[[$OV_VISIBLE]] ])
      assert.is_true(ov[ 2 --[[$OV_ANIMATION]] ].visible)
    end)

    it("keeps overlay hidden when entity status is not working/low_power", function ()
      local r = make_renderer()
      local force = make_force(1)
      force.current_research = ({ research_unit_ingredients = {} }) --[[@as LuaTechnology]]

      r.player_tracker.force = force
      local lab = make_entity(1, 1, 0, 0)
      -- not working, not low_power
      lab.status = defines.entity_status.normal
      local ov = r:render_overlay_for_lab(lab)
      assert.is_not_nil(ov) --- @cast ov -nil

      activate_view(r, 1, force, -1, -1, 1, 1)
      r:update_overlay_states()

      assert.is_false(ov[ 6 --[[$OV_VISIBLE]] ])
      assert.are.equal(0, #r.visible_overlays)
    end)

    it("keeps overlay hidden when no research is active", function ()
      local r = make_renderer()
      local force = make_force(1)
      force.current_research = nil -- no research

      r.player_tracker.force = force
      local lab = make_entity(1, 1, 0, 0)
      lab.status = defines.entity_status.working
      local ov = r:render_overlay_for_lab(lab)
      assert.is_not_nil(ov) --- @cast ov -nil

      activate_view(r, 1, force, -1, -1, 1, 1)
      r:update_overlay_states()

      assert.is_false(ov[ 6 --[[$OV_VISIBLE]] ])
      assert.are.equal(0, #r.visible_overlays)
    end)

    it("low_power labs are treated as visible", function ()
      local r = make_renderer()
      local force = make_force(1)
      force.current_research = ({ research_unit_ingredients = {} }) --[[@as LuaTechnology]]

      r.player_tracker.force = force
      local lab = make_entity(1, 1, 0, 0)
      lab.status = defines.entity_status.low_power
      local ov = r:render_overlay_for_lab(lab)
      assert.is_not_nil(ov) --- @cast ov -nil

      activate_view(r, 1, force, -1, -1, 1, 1)
      r:update_overlay_states()

      assert.is_true(ov[ 6 --[[$OV_VISIBLE]] ])
    end)

    it("does not include labs outside the chunk range in visible_overlays", function ()
      local r = make_renderer()
      local force = make_force(1)
      force.current_research = ({ research_unit_ingredients = {} }) --[[@as LuaTechnology]]

      r.player_tracker.force = force
      -- Lab at (0,0) → chunk (0,0)
      r:render_overlay_for_lab(make_entity(1, 1, 0, 0))

      -- View covers chunks (5,5)–(6,6) only → lab at (0,0) is outside
      activate_view(r, 1, force, 5, 5, 6, 6)
      r:update_overlay_states()

      assert.are.equal(0, #r.visible_overlays)
    end)

    it("updates current_research and current_research_colors when research changes", function ()
      local r = make_renderer()
      local force = make_force(1)
      local new_tech = ({
        research_unit_ingredients = { { name = "automation-science-pack" } },
      }) --[[@as LuaTechnology]]
      force.current_research = new_tech
      r.color_registry:set_ingredient_color("automation-science-pack", { 0.9, 0.1, 0.2 })

      activate_view(r, 1, force, -1, -1, 1, 1)
      r:update_overlay_states()

      assert.are.equal(new_tech, r.current_research)
      assert.is_not_nil(r.current_research_colors)
    end)

    it("clears current_research_colors when research stops", function ()
      local r = make_renderer()
      local force = make_force(1)

      -- Seed with some research
      r.current_research = ({ research_unit_ingredients = {} }) --[[@as LuaTechnology]]
      r.current_research_colors = { { 1, 0, 1 } }

      force.current_research = nil -- research ended
      activate_view(r, 1, force, -1, -1, 1, 1)
      r:update_overlay_states()

      assert.is_nil(r.current_research)
      assert.is_nil(r.current_research_colors)
    end)

    it("clears trailing entries from visible_overlays after labs leave the view", function ()
      local r = make_renderer()
      local force = make_force(1)

      -- Inject a stale entry
      local stale_ov = make_overlay(99, 1, 0, 0)
      r.visible_overlays[1] = stale_ov

      force.current_research = nil
      -- View with no labs → count stays 0
      activate_view(r, 1, force, 100, 100, 101, 101)
      r:update_overlay_states()

      assert.is_nil(r.visible_overlays[1])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("get_tick_function", function ()
    it("returns a function", function ()
      local r = make_renderer()
      assert.is_function(r:get_tick_function())
    end)

    it("returns early without error when view is invalid", function ()
      local r = make_renderer()
      local tick = r:get_tick_function()
      -- view[PV_VALID] is false by default
      assert.no_error(tick)
    end)

    it("returns early without error when current_research_colors is nil", function ()
      local r = make_renderer()
      local tick = r:get_tick_function()
      r.player_tracker.view[ 1 --[[$PV_VALID]] ] = true
      r.current_research_colors = nil
      assert.no_error(tick)
    end)

    it("updates animation.color for visible overlays", function ()
      _G.settings.global[ "mks-dsl-lab-update-interval" --[[$LAB_UPDATE_INTERVAL_NAME]] ].value = 1

      local r = make_renderer()
      r.player_tracker.view[ 1 --[[$PV_VALID]] ] = true
      r.current_research_colors = { { 1.0, 0.0, 0.5 } }
      r.player_tracker.position[1] = 0
      r.player_tracker.position[2] = 0

      local tick = r:get_tick_function()

      -- Populate the captured visible_overlays table after getting the tick function
      local written = false
      local mock_anim = setmetatable({}, {
        __index = { valid = true, visible = true },
        __newindex = function (t, k, v)
          if k == "color" then written = true end
          rawset(t, k, v)
        end,
      })
      local ov = make_overlay(1, 1, 0, 0)
      ov[ 2 --[[$OV_ANIMATION]] ] = mock_anim --[[@as LuaRenderObject]]
      r.visible_overlays[1] = ov

      assert.no_error(tick)
      assert.is_true(written)
    end)

    it("uses stride: updates only 1/N overlays per tick when lab_update_interval=N", function ()
      _G.settings.global[ "mks-dsl-lab-update-interval" --[[$LAB_UPDATE_INTERVAL_NAME]] ].value = 3

      local r = make_renderer()
      r.player_tracker.view[ 1 --[[$PV_VALID]] ] = true
      r.current_research_colors = { { 1.0, 0.0, 0.0 } }
      r.player_tracker.position[1] = 0
      r.player_tracker.position[2] = 0

      local tick = r:get_tick_function()

      -- Track which overlays had their color written
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
        local ov = make_overlay(i, 1, 0, 0)
        ov[ 2 --[[$OV_ANIMATION]] ] = anim --[[@as LuaRenderObject]]
        r.visible_overlays[i] = ov
      end

      -- First tick: lab_update_offset increments from 1 to 2
      -- With interval=3, iterates i=2 only (stride=3 skips others)
      tick()
      assert.are.equal(1, #colored)
      assert.are.equal(2, colored[1])
    end)

    it("increments through all strides across multiple ticks", function ()
      _G.settings.global[ "mks-dsl-lab-update-interval" --[[$LAB_UPDATE_INTERVAL_NAME]] ].value = 3

      local r = make_renderer()
      r.player_tracker.view[ 1 --[[$PV_VALID]] ] = true
      r.current_research_colors = { { 1.0, 0.0, 0.0 } }
      r.player_tracker.position[1] = 0
      r.player_tracker.position[2] = 0

      local tick = r:get_tick_function()

      local color_calls = {}
      for i = 1, 3 do
        local idx = i
        local anim = setmetatable({}, {
          __index = { valid = true, visible = true },
          __newindex = function (t, k, v)
            if k == "color" then color_calls[#color_calls + 1] = idx end
            rawset(t, k, v)
          end,
        })
        local ov = make_overlay(i, 1, 0, 0)
        ov[ 2 --[[$OV_ANIMATION]] ] = anim --[[@as LuaRenderObject]]
        r.visible_overlays[i] = ov
      end

      -- 3 ticks cover offsets 2, 3, 1 (then wraps) → all three overlays colored once each
      tick()
      tick()
      tick()
      table.sort(color_calls)
      assert.are.same({ 1, 2, 3 }, color_calls)
    end)

    -- -------------------------------------------------------------------
    describe("color_pattern_duration", function ()
      -- Spy on ColorFunctions.choose_random to count how often the color function is switched.
      -- The closure in get_tick_function() looks up ColorFunctions.choose_random as a table
      -- field access, so replacing it here affects the live tick function.
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

      --- Build a renderer with an active view and research colors, return its tick function.
      --- @return fun()
      local function make_active_tick()
        local r = make_renderer()
        r.player_tracker.view[ 1 --[[$PV_VALID]] ] = true
        r.current_research_colors = { { 1.0, 0.0, 0.0 } }
        r.player_tracker.position[1] = 0
        r.player_tracker.position[2] = 0
        return r:get_tick_function() -- counts as 1 cf_call (initial choose_random)
      end

      it("does not switch color function before duration is reached", function ()
        _G.settings.global[ "mks-dsl-color-pattern-duration" --[[$COLOR_PATTERN_DURATION_NAME]] ].value = 3
        local tick = make_active_tick() -- cf_calls = 1 (initial)
        tick()                          -- counter = 1, no switch
        tick()                          -- counter = 2, no switch
        assert.are.equal(1, cf_calls)
      end)

      it("switches color function exactly when duration is reached", function ()
        _G.settings.global[ "mks-dsl-color-pattern-duration" --[[$COLOR_PATTERN_DURATION_NAME]] ].value = 3
        local tick = make_active_tick() -- cf_calls = 1 (initial)
        tick()                          -- counter = 1, no switch
        tick()                          -- counter = 2, no switch
        tick()                          -- counter = 3 >= 3, switch → cf_calls = 2
        assert.are.equal(2, cf_calls)
      end)

      it("resets counter and switches again after another full duration", function ()
        _G.settings.global[ "mks-dsl-color-pattern-duration" --[[$COLOR_PATTERN_DURATION_NAME]] ].value = 2
        local tick = make_active_tick() -- cf_calls = 1 (initial)
        tick()                          -- counter = 1, no switch
        tick()                          -- counter = 2 >= 2, switch → cf_calls = 2, counter resets to 0
        tick()                          -- counter = 1, no switch
        tick()                          -- counter = 2 >= 2, switch → cf_calls = 3
        assert.are.equal(3, cf_calls)
      end)

      it("switches every tick when duration is 1", function ()
        _G.settings.global[ "mks-dsl-color-pattern-duration" --[[$COLOR_PATTERN_DURATION_NAME]] ].value = 1
        local tick = make_active_tick() -- cf_calls = 1 (initial)
        tick()                          -- counter = 1 >= 1, switch → cf_calls = 2
        tick()                          -- counter = 1 >= 1, switch → cf_calls = 3
        tick()                          -- counter = 1 >= 1, switch → cf_calls = 4
        assert.are.equal(4, cf_calls)
      end)
    end)
  end)
end)
