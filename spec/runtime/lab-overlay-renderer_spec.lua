local ColorRegistry = require("scripts.runtime.color-registry")
local LabRegistry = require("scripts.runtime.lab-registry")
local ColorFunctions = require("scripts.runtime.color-functions")
local LabOverlayRenderer = require("scripts.runtime.lab-overlay-renderer")
local Settings = require("scripts.shared.settings")
local reset_mocks = require("spec.helper").reset_mocks

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
--- @return LabOverlay
local function make_overlay(unit_number, surface_index, x, y)
  x = x or 0
  y = y or 0
  surface_index = surface_index or 1
  local entity = make_entity(unit_number, surface_index, x, y)
  local anim = { valid = true, visible = false, color = { 0, 0, 0 } }
  anim.destroy = function () anim.valid = false end
  return {
    entity      = entity,
    animation   = anim --[[@as LuaRenderObject]],
    x           = x,
    y           = y,
    visible     = false,
    unit_number = unit_number,
  }
end

--- Build a LabOverlayRenderer with empty registries.
--- @return LabOverlayRenderer
local function make_renderer()
  return LabOverlayRenderer.new(ColorRegistry.new(), LabRegistry.new())
end

--- Build a mock LuaPlayer.
--- @param force LuaForce
--- @param surface_index number
--- @param px number?
--- @param py number?
--- @return LuaPlayer
local function make_player(force, surface_index, px, py)
  return ({
    render_mode = defines.render_mode.game,
    force = force,
    surface_index = surface_index,
    position = { x = px or 0, y = py or 0 },
    zoom = 1,
    display_resolution = { width = 640, height = 480 },
  }) --[[@as LuaPlayer]]
end

--- Set the single connected player in game.players[1].
--- @param force LuaForce
--- @param surface_index number
--- @param px number?
--- @param py number?
--- @return LuaPlayer
local function add_connected_player(force, surface_index, px, py)
  local player = make_player(force, surface_index, px, py)
  player.index = 1 --[[@as integer]]
  _G.game.players[1] = player
  return player
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
      assert.is_nil(r.colors)
      assert.are.equal(0, r.n_colors)
      assert.is_nil(r.current_research)
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

    it("returns nil when lab is excluded", function ()
      local r = make_renderer()
      Settings.is_fallback_enabled = true
      r.lab_registry.excluded_labs["lab"] = true
      assert.is_nil(r:render_overlay_for_lab(make_entity(1, 1, 0, 0)))
    end)

    it("returns nil when lab is not registered and fallback disabled", function ()
      local r = make_renderer()
      Settings.is_fallback_enabled = false
      -- lab_registry has no registration for "lab"
      local result = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_nil(result)
    end)

    it("creates and returns an overlay with correct initial values", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { animation = "lab-anim", scale = 1.5 })
      local ov = r:render_overlay_for_lab(make_entity(77, 1, 0, 0))

      assert.is_not_nil(ov) --- @cast ov -nil
      assert.are.equal(77, ov.unit_number)
      assert.is_false(ov.visible)
      assert.are.equal("lab-anim", ov.animation.animation)
      assert.are.equal(1.5, ov.animation.x_scale)
      assert.is_nil(ov.companion)
    end)

    it("creates companion render object when companion is registered", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { animation = "lab-anim", companion = "comp-anim", scale = 1.5 })
      local ov = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))

      assert.is_not_nil(ov)        --- @cast ov -nil
      local companion = ov.companion
      assert.is_not_nil(companion) --- @cast companion -nil
      assert.are.equal("comp-anim", companion.animation)
      assert.are.equal(1.5, companion.x_scale)
      assert.are.equal("higher-object-above", companion.render_layer)
    end)

    it("reuses existing companion render object when provided", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { animation = "lab-anim", companion = "comp-anim" })
      local lab = make_entity(1, 1, 0, 0)
      local ov1 = r:render_overlay_for_lab(lab)
      assert.is_not_nil(ov1)   --- @cast ov1 -nil
      local comp1 = ov1.companion
      assert.is_not_nil(comp1) --- @cast comp1 -nil

      local ov2 = r:render_overlay_for_lab(lab, ov1.animation, comp1)
      assert.is_not_nil(ov2) --- @cast ov2 -nil
      assert.are.equal(comp1, ov2.companion)
    end)

    it("creates overlay using general overlay when no registration but fallback enabled", function ()
      local r = make_renderer()
      Settings.is_fallback_enabled = true
      -- lab_registry has no registration for "lab"
      local overlay = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_not_nil(overlay) --- @cast overlay -nil
      assert.are.equal("mks-dsl-general-overlay" --[[$GENERAL_OVERLAY_ANIMATION_NAME]], overlay.animation.animation)
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
      assert.are_not.equal(ov1.animation, ov2.animation)
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
      local anim1_id = r.overlays[1].animation.id

      -- Second render (rebuild)
      r:render_overlays_for_all_labs()
      assert.are.equal(anim1_id, r.overlays[1].animation.id)
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
      local anim2_id = r.overlays[2].animation.id

      -- Rebuild with only lab1 remaining
      --- @diagnostic disable-next-line: duplicate-set-field
      lab1.surface.find_entities_filtered = function () return { lab1 } end
      r:render_overlays_for_all_labs()

      assert.is_nil(_G.rendering.objects[orphan_id])
      assert.is_nil(_G.rendering.objects[anim2_id])
    end)

    it("reuses existing companion render object", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { companion = "comp-anim" })
      local lab = make_entity(1, 1, 0, 0)
      _G.game.surfaces = { [1] = lab.surface }
      lab.surface.find_entities_filtered = function () return { lab } end

      r:render_overlays_for_all_labs()
      local comp1_id = r.overlays[1].companion.id

      r:render_overlays_for_all_labs()
      assert.are.equal(comp1_id, r.overlays[1].companion.id)
    end)

    it("destroys companion when lab is removed", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { companion = "comp-anim" })
      local lab = make_entity(1, 1, 0, 0)
      _G.game.surfaces = { [1] = lab.surface }
      --- @diagnostic disable-next-line: duplicate-set-field
      lab.surface.find_entities_filtered = function () return { lab } end

      r:render_overlays_for_all_labs()
      local comp_id = r.overlays[1].companion.id

      --- @diagnostic disable-next-line: duplicate-set-field
      lab.surface.find_entities_filtered = function () return {} end
      r:render_overlays_for_all_labs()

      assert.is_nil(_G.rendering.objects[comp_id])
    end)

    it("destroys all existing render objects and creates new ones when force=true", function ()
      local r = make_renderer()
      local lab = make_entity(1, 1, 0, 0)
      _G.game.surfaces = { [1] = lab.surface }
      lab.surface.find_entities_filtered = function () return { lab } end

      -- Initial render
      r:render_overlays_for_all_labs()
      local old_anim_id = r.overlays[1].animation.id

      -- Force re-render: must destroy old objects and create new ones
      r:render_overlays_for_all_labs(true)
      local new_anim_id = r.overlays[1].animation.id

      assert.is_nil(_G.rendering.objects[old_anim_id])
      assert.are_not.equal(old_anim_id, new_anim_id)
      assert.is_not_nil(_G.rendering.objects[new_anim_id])
    end)

    it("resets research state when force=true", function ()
      local r = make_renderer()
      local lab = make_entity(1, 1, 0, 0)
      _G.game.surfaces = { [1] = lab.surface }
      lab.surface.find_entities_filtered = function () return { lab } end

      r:render_overlays_for_all_labs()
      -- Set colors to a non-nil value to verify reset.
      r.colors = { 1, 0, 0 }
      r.n_colors = 1
      r.current_research = make_tech()

      -- No player set: update_current_research will reset to nil.
      r:render_overlays_for_all_labs(true)

      assert.is_nil(r.colors)
      assert.are.equal(0, r.n_colors)
      assert.is_nil(r.current_research)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("remove_overlay_from_lab", function ()
    it("removes overlay from data structures and destroys animation", function ()
      local r = make_renderer()
      local ov = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_not_nil(ov) --- @cast ov -nil
      local anim = ov.animation
      r.visible_overlays[1] = ov

      r:remove_overlay_from_lab(1)

      assert.is_nil(r.overlays[1])
      assert.is_nil(r.chunk_map.entries[1])
      assert.is_false(anim.valid)
      assert.are.equal(1, #r.visible_overlays) -- does not remove it from visible_overlays
    end)

    it("destroys companion render object when present", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { companion = "comp-anim" })
      local ov = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_not_nil(ov)        --- @cast ov -nil
      local companion = ov.companion
      assert.is_not_nil(companion) --- @cast companion -nil

      r:remove_overlay_from_lab(1)

      assert.is_false(companion.valid)
    end)

    it("does not error for unknown unit_number or invalid animation", function ()
      local r = make_renderer()
      local ov = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_not_nil(ov) --- @cast ov -nil
      ov.animation.valid = false

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
      local anim1 = r:render_overlay_for_lab(make_entity(1, 1, 0, 0)).animation
      local anim2 = r:render_overlay_for_lab(make_entity(2, 2, 0, 0)).animation

      r:remove_overlays_on_surface(2)

      assert.is_not_nil(r.overlays[1])
      assert.is_true(anim1.valid)
      assert.is_nil(r.overlays[2])
      assert.is_false(anim2.valid)
      assert.is_nil(r.chunk_map.data[2])
    end)

    it("destroys companion render objects on target surface", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { companion = "comp-anim" })
      local ov = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_not_nil(ov)        --- @cast ov -nil
      local companion = ov.companion
      assert.is_not_nil(companion) --- @cast companion -nil

      r:remove_overlays_on_surface(1)

      assert.is_false(companion.valid)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("update_lab_position", function ()
    it("updates position on the same surface", function ()
      local r = make_renderer()
      local lab = make_entity(1, 1, 0, 0)
      r:render_overlay_for_lab(lab)

      lab.position = { x = 32, y = 64 }
      r:update_lab_position(lab)

      local ov = r.overlays[1]
      assert.are.equal(32, ov.x)
      assert.are.equal(64, ov.y)
      assert.are.equal(lab, ov.animation.target)
    end)

    it("updates companion target on the same surface", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { companion = "comp-anim" })
      local lab = make_entity(1, 1, 0, 0)
      r:render_overlay_for_lab(lab)

      lab.position = { x = 32, y = 64 }
      r:update_lab_position(lab)

      assert.are.equal(lab, r.overlays[1].companion.target)
    end)

    it("triggers re-render when companion is invalid", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { companion = "comp-anim" })
      local lab = make_entity(1, 1, 0, 0)
      r:render_overlay_for_lab(lab)
      local old_comp_id = r.overlays[1].companion.id

      r.overlays[1].companion.valid = false
      r:update_lab_position(lab)

      assert.are_not.equal(old_comp_id, r.overlays[1].companion.id)
    end)

    it("rebuilds overlay when lab teleports to another surface", function ()
      local r = make_renderer()
      local lab = make_entity(1, 1, 0, 0)
      r:render_overlay_for_lab(lab)
      local old_anim = r.overlays[1].animation

      lab.surface_index = 2
      lab.surface = ({ index = 2 }) --[[@as LuaSurface]]
      r:update_lab_position(lab)

      assert.is_false(old_anim.valid)
      assert.are.equal(2, r.overlays[1].animation.surface.index)
    end)

    it("destroys companion when lab teleports to another surface", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { companion = "comp-anim" })
      local lab = make_entity(1, 1, 0, 0)
      r:render_overlay_for_lab(lab)
      local old_companion = r.overlays[1].companion
      assert.is_not_nil(old_companion) --- @cast old_companion -nil

      lab.surface_index = 2
      lab.surface = ({ index = 2 }) --[[@as LuaSurface]]
      r:update_lab_position(lab)

      assert.is_false(old_companion.valid)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("update_current_research", function ()
    it("updates research and flattens colors", function ()
      local r = make_renderer()
      local force = make_force(1)
      local tech = make_tech({ "automation-science-pack", "logistic-science-pack" })
      force.current_research = tech
      _G.game.players[1] = make_player(force, 1)

      r.color_registry:set_ingredient_color("automation-science-pack", { 1, 0, 0 })
      r.color_registry:set_ingredient_color("logistic-science-pack", { 0, 1, 0 })

      r:update_current_research()

      assert.are.equal(tech, r.current_research)
      assert.are.same({ 1, 0, 0, 0, 1, 0 }, r.colors)
      assert.are.equal(2, r.n_colors)
    end)

    it("clears colors when research is nil", function ()
      local r = make_renderer()
      local force = make_force(1)
      force.current_research = nil
      _G.game.players[1] = make_player(force, 1)
      r.colors = { 1, 1, 1 }
      r.n_colors = 1

      r:update_current_research()

      assert.is_nil(r.colors)
      assert.are.equal(0, r.n_colors)
    end)

    it("clears state when player does not exist", function ()
      local r = make_renderer()
      r.colors = { 1, 0, 0 }
      r.n_colors = 1
      r.current_research = make_tech()
      -- game.players[1] is nil (not set)

      r:update_current_research()

      assert.is_nil(r.colors)
      assert.are.equal(0, r.n_colors)
      assert.is_nil(r.current_research)
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

      add_connected_player(force, 1)
      r:get_state_update_function()()

      assert.is_not_nil(ov_working) --- @cast ov_working -nil
      assert.is_not_nil(ov_normal)  --- @cast ov_normal -nil
      assert.are.equal(1, #r.visible_overlays)
      assert.is_true(ov_working.visible)
      assert.is_false(ov_normal.visible)
    end)

    it("syncs companion visibility when overlay becomes visible", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { companion = "comp-anim" })
      local force = make_force(1)
      local ov = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_not_nil(ov)        --- @cast ov -nil
      local companion = ov.companion
      assert.is_not_nil(companion) --- @cast companion -nil

      add_connected_player(force, 1)
      r:get_state_update_function()()

      assert.is_true(companion.visible)
    end)

    it("syncs companion visibility when overlay becomes hidden", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { companion = "comp-anim" })
      local force = make_force(1)
      local lab = make_entity(1, 1, 0, 0)
      local ov = r:render_overlay_for_lab(lab)
      assert.is_not_nil(ov)        --- @cast ov -nil
      local companion = ov.companion
      assert.is_not_nil(companion) --- @cast companion -nil

      -- Make visible first
      add_connected_player(force, 1)
      local update = r:get_state_update_function()
      update()
      assert.is_true(companion.visible)

      -- Now make it hidden (lab stops working)
      lab.status = defines.entity_status.normal
      update()
      assert.is_false(companion.visible)
    end)

    it("updates current_research and colors based on force research changes", function ()
      local r = make_renderer()
      local force = make_force(1)
      local tech = make_tech({ "automation-science-pack" })
      force.current_research = tech
      r.color_registry:set_ingredient_color("automation-science-pack", { 1, 1, 1 })

      add_connected_player(force, 1, 10, 20)

      local update = r:get_state_update_function()
      update()

      assert.are.equal(tech, r.current_research)
      assert.is_not_nil(r.colors)

      force.current_research = nil
      update()
      assert.is_nil(r.current_research)
      assert.are.equal(0, r.n_colors)
    end)

    it("replaces stale visible_overlays entries and clears trailing entries", function ()
      local r = make_renderer()
      local force = make_force(1)
      r:render_overlay_for_lab(make_entity(1, 1, 0, 0))

      -- Stale entries from a previous state update.
      r.visible_overlays[1] = make_overlay(99, 1, 0, 0)
      r.visible_overlays[2] = make_overlay(98, 1, 0, 0)

      add_connected_player(force, 1)

      r:get_state_update_function()()

      -- Only the 1 real lab should be present; stale entry at [2] must be cleared.
      assert.are.equal(1, #r.visible_overlays)
      assert.is_nil(r.visible_overlays[2])
    end)

    it("sets current_interval to 1 when visible labs fit within 500", function ()
      local r = make_renderer()
      local force = make_force(1)
      for i = 1, 10 do
        r:render_overlay_for_lab(make_entity(i, 1, 0, 0))
      end
      add_connected_player(force, 1)

      r:get_state_update_function()()

      assert.are.equal(1, r.current_interval)
    end)

    it("increases current_interval when visible labs exceed 500", function ()
      local r = make_renderer()
      local force = make_force(1)
      for i = 1, 1000 do
        r:render_overlay_for_lab(make_entity(i, 1, 0, 0))
      end
      add_connected_player(force, 1)

      r:get_state_update_function()()

      -- ceil(1000 / 500) = 2
      assert.are.equal(2, r.current_interval)
    end)

    it("caps current_interval at 60", function ()
      local r = make_renderer()
      local force = make_force(1)
      for i = 1, 30001 do
        r:render_overlay_for_lab(make_entity(i, 1, 0, 0))
      end
      add_connected_player(force, 1)

      r:get_state_update_function()()

      -- ceil(30001 / 500) = 61, capped at 60
      assert.are.equal(60, r.current_interval)
    end)

    -- -------------------------------------------------------------------
    describe("player view filtering", function ()
      -- At zoom=1, 640x480, player at (0,0):
      --   f = 64, half_vw = ceil(10) = 10, half_vh = ceil(7.5) = 8
      --   chunk_right = floor((10 + 6) * 0.03125) = floor(0.5) = 0
      -- So chunk x=1 (world x=32..63) is outside the view.

      it("skips all overlays when player is in chart mode", function ()
        local r = make_renderer()
        local force = make_force(1)
        r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
        local player = add_connected_player(force, 1)
        player.render_mode = defines.render_mode.chart

        r:get_state_update_function()()

        assert.are.equal(0, #r.visible_overlays)
      end)

      it("excludes labs outside the player's chunk range", function ()
        local r = make_renderer()
        local force = make_force(1)
        -- Lab at x=32 is in chunk 1, which is outside the view range [−1, 0].
        r:render_overlay_for_lab(make_entity(1, 1, 32, 0))
        add_connected_player(force, 1, 0, 0)

        r:get_state_update_function()()

        assert.are.equal(0, #r.visible_overlays)
      end)

      it("includes labs inside the player's chunk range", function ()
        local r = make_renderer()
        local force = make_force(1)
        -- Lab at x=0 is in chunk 0, which is inside the view range [−1, 0].
        r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
        add_connected_player(force, 1, 0, 0)

        r:get_state_update_function()()

        assert.are.equal(1, #r.visible_overlays)
      end)

      it("wider view at lower zoom includes previously-out-of-range labs", function ()
        local r = make_renderer()
        local force = make_force(1)
        -- Lab at x=32 (chunk 1) is outside at zoom=1 but inside at zoom=0.25:
        --   f = 16, half_vw = ceil(40) = 40, chunk_right = floor(46 * 0.03125) = 1
        r:render_overlay_for_lab(make_entity(1, 1, 32, 0))
        local player = add_connected_player(force, 1, 0, 0)
        player.zoom = 0.25

        r:get_state_update_function()()

        assert.are.equal(1, #r.visible_overlays)
      end)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("get_tick_function", function ()
    it("updates animation.color for visible overlays", function ()
      local r = make_renderer()
      r.current_interval = 1
      r.colors = { 1.0, 0.0, 0.5 }
      r.n_colors = 1

      local written = false
      local mock_anim = setmetatable({}, {
        __index = { valid = true, visible = true },
        __newindex = function (t, k, v)
          if k == "color" then written = true end
          rawset(t, k, v)
        end,
      })
      local ov = make_overlay(1, 1, 0, 0)
      ov.animation = mock_anim --[[@as LuaRenderObject]]
      r.visible_overlays[1] = ov

      r:get_tick_function(LabOverlayRenderer.create_anim_state())()
      assert.is_true(written)
    end)

    it("uses stride: updates only 1/N overlays per tick when current_interval=N", function ()
      local r = make_renderer()
      r.current_interval = 3
      r.colors = { 1.0, 0.0, 0.5 }
      r.n_colors = 1

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
        ov.animation = anim --[[@as LuaRenderObject]]
        r.visible_overlays[i] = ov
      end

      local tick = r:get_tick_function(LabOverlayRenderer.create_anim_state())
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
        Settings.color_pattern_duration = 3
        r.colors = { 1.0, 0.0, 0.0 }
        r.n_colors = 1
        r.visible_overlays[1] = make_overlay(1, 1, 0, 0)

        local tick = r:get_tick_function(LabOverlayRenderer.create_anim_state())
        -- starts with cf_calls = 1
        tick() -- 1
        tick() -- 2
        tick() -- 3 >= 3, switch! cf_calls = 2
        assert.are.equal(2, cf_calls)
      end)

      it("divides color_pattern_duration by color_update_interval", function ()
        local r = make_renderer()
        Settings.color_pattern_duration = 6
        Settings.color_update_interval = 3
        r.colors = { 1.0, 0.0, 0.0 }
        r.n_colors = 1
        r.visible_overlays[1] = make_overlay(1, 1, 0, 0)

        -- ceil(6 / 3) = 2 ticks per epoch, not 6
        local tick = r:get_tick_function(LabOverlayRenderer.create_anim_state())
        -- starts with cf_calls = 1
        tick() -- elapsed=1, no switch yet
        assert.are.equal(1, cf_calls)
        tick() -- elapsed=2 >= 2, switch! cf_calls = 2
        assert.are.equal(2, cf_calls)
      end)
    end)

    -- -------------------------------------------------------------------
    describe("anim_state", function ()
      local original_fns = {}
      local captured_phase

      before_each(function ()
        captured_phase = nil
        for i = 1, #ColorFunctions.functions do
          original_fns[i] = ColorFunctions.functions[i]
          local orig = original_fns[i]
          ColorFunctions.functions[i] = function (color, phase, ...)
            captured_phase = phase
            return orig(color, phase, ...)
          end
        end
      end)

      after_each(function ()
        for i = 1, #original_fns do
          ColorFunctions.functions[i] = original_fns[i]
        end
      end)

      --- @return AnimState
      local function make_anim_state(phase, phase_speed, saved_tick_offset)
        local _, cf_idx = ColorFunctions.choose_random()
        return ({
          phase = phase,
          phase_speed = phase_speed,
          color_function_index = cf_idx,
          saved_tick = _G.game.tick - (saved_tick_offset or 0),
        }) --[[@as AnimState]]
      end

      local function make_renderer_with_overlay()
        local r = make_renderer()
        r.current_interval = 1
        r.colors = { 1.0, 0.0, 0.0 }
        r.n_colors = 1
        r.visible_overlays[1] = make_overlay(1, 1, 0, 0)
        return r
      end

      it("restores phase from anim_state.phase", function ()
        local r = make_renderer_with_overlay()
        -- phase=2.0, phase_speed=0.25, saved_tick=game.tick (no elapsed)
        local anim_state = make_anim_state(2.0, 0.25, 0)

        r:get_tick_function(anim_state)()

        -- phase = 2.0 + 0 * 0.25 (no elapsed) + 0.25 (one tick advance) = 2.25
        assert.are.equal(2.25, captured_phase)
      end)

      it("accounts for elapsed ticks since saved_tick", function ()
        local r = make_renderer_with_overlay()
        -- phase=0.0, phase_speed=0.25, saved_tick=game.tick - 4 (4 elapsed ticks)
        local anim_state = make_anim_state(0.0, 0.25, 4)

        r:get_tick_function(anim_state)()

        -- phase = 0.0 + 4 * 0.25 (elapsed) + 0.25 (one tick advance) = 1.25
        assert.are.equal(1.25, captured_phase)
      end)

      it("writes back phase and saved_tick to anim_state at epoch end", function ()
        local r = make_renderer_with_overlay()
        Settings.color_pattern_duration = 3
        local anim_state = make_anim_state(0.0, 0.25, 0)

        local tick = r:get_tick_function(anim_state)
        tick() -- elapsed=1, phase=0.25 — not yet written back
        tick() -- elapsed=2, phase=0.50 — not yet written back
        assert.are.equal(0.0, anim_state.phase)

        tick() -- elapsed=3 >= 3 → write back!
        assert.are.equal(0.75, anim_state.phase)
        assert.are.equal(_G.game.tick, anim_state.saved_tick)
      end)

      it("new tick function resumes with elapsed ticks after write-back", function ()
        local r = make_renderer_with_overlay()
        Settings.color_pattern_duration = 2
        local anim_state = make_anim_state(0.0, 0.25, 0)

        -- Run first tick function until epoch end
        local tick1 = r:get_tick_function(anim_state)
        tick1() -- elapsed=1, phase=0.25
        tick1() -- elapsed=2 >= 2 → write back: phase=0.50, saved_tick=game.tick

        local written_phase = anim_state.phase
        local written_phase_speed = anim_state.phase_speed

        -- Advance game.tick to simulate 3 ticks passing since the write-back
        _G.game.tick = _G.game.tick + 3

        -- Create a new tick function from the written-back anim_state and call once
        local tick2 = r:get_tick_function(anim_state)
        tick2()

        -- phase = written_phase + 3 * written_phase_speed (elapsed) + written_phase_speed (one tick)
        -- Use same evaluation order as the implementation to avoid floating-point divergence.
        local expected = (written_phase + 3 * written_phase_speed) + written_phase_speed
        assert.are.equal(expected, captured_phase)
      end)
    end)
  end)
end)
