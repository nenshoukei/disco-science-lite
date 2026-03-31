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
  local name = "force_" .. index
  local force = ({ index = index, name = name, current_research = make_tech() }) --[[@as LuaForce]]
  _G.game.forces[name] = force
  return force
end

--- Build a mock LuaEntity representing a lab on a given surface.
--- @param unit_number number
--- @param surface_index number
--- @param x number?
--- @param y number?
--- @param force LuaForce?
--- @return LuaEntity
local function make_entity(unit_number, surface_index, x, y, force)
  x = x or 0
  y = y or 0
  force = force or make_force(1)
  return ({
    valid         = true,
    type          = "lab",
    unit_number   = unit_number,
    surface_index = surface_index,
    force_index   = force.index,
    force         = force,
    name          = "lab",
    position      = { x = x, y = y },
    tile_width    = 3,
    tile_height   = 3,
    prototype     = { tile_width = 3, tile_height = 3 },
    surface       = ({ index = surface_index }) --[[@as LuaSurface]],
    status        = defines.entity_status.working,
  }) --[[@as LuaEntity]]
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
    zoom_limits = { furthest_game_view = { zoom = 0.1 } },
    display_resolution = { width = 640, height = 480 },
  }) --[[@as LuaPlayer]]
end

--- Set the single connected player in game.players[1].
--- @param index integer
--- @param force LuaForce
--- @param surface_index number
--- @param px number?
--- @param py number?
--- @return LuaPlayer
local function add_connected_player_at(index, force, surface_index, px, py)
  local player = make_player(force, surface_index, px, py)
  player.index = index --[[@as integer]]
  _G.game.players[index] = player
  _G.game.connected_players[index] = player
  return player
end

--- Set the single connected player in game.players[1].
--- @param force LuaForce
--- @param surface_index number
--- @param px number?
--- @param py number?
--- @return LuaPlayer
local function add_connected_player(force, surface_index, px, py)
  return add_connected_player_at(1, force, surface_index, px, py)
end

--- Set up a renderer with visible overlays and active research, ready for tick testing.
--- The first tick call will trigger a state update (state_update_counter starts > 30).
---
--- @param opts { n_overlays: integer?, x: number?, y: number? }?
--- @return LabOverlayRenderer renderer
--- @return LuaForce force
local function setup_tick_renderer(opts)
  opts = opts or {}
  local n_overlays = opts.n_overlays or 1
  local x = opts.x or 0
  local y = opts.y or 0
  local r = make_renderer()
  r.color_registry:set_ingredient_color("automation-science-pack", { 1, 0, 0 })
  local force = make_force(1)
  force.current_research = make_tech({ "automation-science-pack" })
  add_connected_player(force, 1, 0, 0)
  for i = 1, n_overlays do
    r:render_overlay_for_lab(make_entity(i, 1, x, y, force))
  end
  return r, force
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
    it("starts with empty chunk map", function ()
      local r = make_renderer()
      assert.are.same({}, r.chunk_map.data)
      assert.are.same({}, r.chunk_map.entries)
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

      assert.is_not_nil(ov)       --- @cast ov -nil
      assert.are.equal(77, ov.unit_number)
      assert.is_false(ov.visible) -- visible starts false; authoritative state is set by tick scan
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
      assert.is_true(companion.visible)
    end)

    it("creates an invisible overlay and companion when current_research is nil", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { animation = "lab-anim", companion = "comp-anim", scale = 1.5 })
      local lab = make_entity(1, 1, 0, 0)
      lab.force.current_research = nil
      local ov = r:render_overlay_for_lab(lab)

      assert.is_not_nil(ov)        --- @cast ov -nil
      local companion = ov.companion
      assert.is_not_nil(companion) --- @cast companion -nil
      assert.is_false(ov.visible)
      assert.is_false(companion.visible)
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
      assert.is_not_nil(r.chunk_map.entries[42])
    end)

    it("reuses existing animation object when called repeatedly for same lab", function ()
      local r = make_renderer()
      local lab = make_entity(1, 1, 0, 0)
      local ov1 = r:render_overlay_for_lab(lab)
      local ov2 = r:render_overlay_for_lab(lab)
      assert.is_not_nil(ov1) --- @cast ov1 -nil
      assert.is_not_nil(ov2) --- @cast ov2 -nil
      assert.are.equal(ov1.animation, ov2.animation)
    end)

    it("destroys existing companion when registration no longer has companion", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { companion = "comp-anim" })
      local lab = make_entity(1, 1, 0, 0)
      local ov1 = r:render_overlay_for_lab(lab)
      assert.is_not_nil(ov1)           --- @cast ov1 -nil
      local old_companion = ov1.companion
      assert.is_not_nil(old_companion) --- @cast old_companion -nil

      r.lab_registry:register("lab", {})
      local ov2 = r:render_overlay_for_lab(lab)
      assert.is_not_nil(ov2) --- @cast ov2 -nil
      assert.is_nil(ov2.companion)
      assert.is_false(old_companion.valid)
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
      local anim1_id = r.chunk_map:get(1).animation.id

      -- Second render (rebuild)
      r:render_overlays_for_all_labs()
      assert.are.equal(anim1_id, r.chunk_map:get(1).animation.id)
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
      local anim2_id = r.chunk_map:get(2).animation.id

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
      local comp1_id = r.chunk_map:get(1).companion.id

      r:render_overlays_for_all_labs()
      assert.are.equal(comp1_id, r.chunk_map:get(1).companion.id)
    end)

    it("destroys companion when lab is removed", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { companion = "comp-anim" })
      local lab = make_entity(1, 1, 0, 0)
      _G.game.surfaces = { [1] = lab.surface }
      --- @diagnostic disable-next-line: duplicate-set-field
      lab.surface.find_entities_filtered = function () return { lab } end

      r:render_overlays_for_all_labs()
      local comp_id = r.chunk_map:get(1).companion.id

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
      local old_anim_id = r.chunk_map:get(1).animation.id

      -- Force re-render: must destroy old objects and create new ones
      r:render_overlays_for_all_labs(true)
      local new_anim_id = r.chunk_map:get(1).animation.id

      assert.is_nil(_G.rendering.objects[old_anim_id])
      assert.are_not.equal(old_anim_id, new_anim_id)
      assert.is_not_nil(_G.rendering.objects[new_anim_id])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("remove_overlay_from_lab", function ()
    it("removes overlay from chunk_map and destroys animation", function ()
      local r = make_renderer()
      local ov = r:render_overlay_for_lab(make_entity(1, 1, 0, 0))
      assert.is_not_nil(ov) --- @cast ov -nil
      local anim = ov.animation

      r:remove_overlay_from_lab(1)

      assert.is_nil(r.chunk_map:get(1))
      assert.is_false(anim.valid)
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

      assert.is_not_nil(r.chunk_map:get(1))
      assert.is_true(anim1.valid)
      assert.is_nil(r.chunk_map:get(2))
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

      local ov = r.chunk_map:get(1)
      assert.is_not_nil(ov) --- @cast ov -nil
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

      assert.are.equal(lab, r.chunk_map:get(1).companion.target)
    end)

    it("triggers re-render when companion is invalid", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { companion = "comp-anim" })
      local lab = make_entity(1, 1, 0, 0)
      r:render_overlay_for_lab(lab)
      local old_comp_id = r.chunk_map:get(1).companion.id

      r.chunk_map:get(1).companion.valid = false
      r:update_lab_position(lab)

      assert.are_not.equal(old_comp_id, r.chunk_map:get(1).companion.id)
    end)

    it("rebuilds overlay when lab teleports to another surface", function ()
      local r = make_renderer()
      local lab = make_entity(1, 1, 0, 0)
      r:render_overlay_for_lab(lab)
      local old_anim = r.chunk_map:get(1).animation

      lab.surface_index = 2
      lab.surface = ({ index = 2 }) --[[@as LuaSurface]]
      r:update_lab_position(lab)

      assert.is_false(old_anim.valid)
      assert.are.equal(2, r.chunk_map:get(1).animation.surface.index)
    end)

    it("destroys companion when lab teleports to another surface", function ()
      local r = make_renderer()
      r.lab_registry:register("lab", { companion = "comp-anim" })
      local lab = make_entity(1, 1, 0, 0)
      r:render_overlay_for_lab(lab)
      local old_companion = r.chunk_map:get(1).companion
      assert.is_not_nil(old_companion) --- @cast old_companion -nil

      lab.surface_index = 2
      lab.surface = ({ index = 2 }) --[[@as LuaSurface]]
      r:update_lab_position(lab)

      assert.is_false(old_companion.valid)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("get_tick_function", function ()
    --- @type EventData.on_tick Mock event for tick function
    local event

    before_each(function ()
      event = ({ tick = game.tick }) --[[@as EventData.on_tick]]
    end)

    local function increment_tick()
      game.tick = game.tick + 1
      event.tick = game.tick
    end

    -- -------------------------------------------------------------------
    describe("state update", function ()
      it("updates visibility based on status and research", function ()
        local r = make_renderer()
        local force = make_force(1)

        local lab_working = make_entity(1, 1, 0, 0, force)
        local ov_working = r:render_overlay_for_lab(lab_working)
        local lab_normal = make_entity(2, 1, 0, 0, force)
        lab_normal.status = defines.entity_status.normal
        local ov_normal = r:render_overlay_for_lab(lab_normal)

        add_connected_player(force, 1)
        -- First tick triggers state update
        r:get_tick_function()(event)

        assert.is_not_nil(ov_working) --- @cast ov_working -nil
        assert.is_not_nil(ov_normal)  --- @cast ov_normal -nil
        assert.is_true(ov_working.visible)
        assert.is_false(ov_normal.visible)
      end)

      it("syncs companion visibility when overlay becomes visible", function ()
        local r = make_renderer()
        r.lab_registry:register("lab", { companion = "comp-anim" })
        local force = make_force(1)
        local ov = r:render_overlay_for_lab(make_entity(1, 1, 0, 0, force))
        assert.is_not_nil(ov)        --- @cast ov -nil
        local companion = ov.companion
        assert.is_not_nil(companion) --- @cast companion -nil

        add_connected_player(force, 1)
        r:get_tick_function()(event)

        assert.is_true(ov.visible)
        assert.is_true(companion.visible)
      end)

      it("syncs companion visibility when overlay becomes hidden", function ()
        local r = make_renderer()
        r.lab_registry:register("lab", { companion = "comp-anim" })
        local force = make_force(1)
        local lab = make_entity(1, 1, 0, 0, force)
        local ov = r:render_overlay_for_lab(lab)
        assert.is_not_nil(ov)        --- @cast ov -nil
        local companion = ov.companion
        assert.is_not_nil(companion) --- @cast companion -nil

        -- Make visible first
        add_connected_player(force, 1)
        local tick, request_state_update = r:get_tick_function()
        tick(event)
        assert.is_true(companion.visible)

        -- Now make it hidden (lab stops working)
        lab.status = defines.entity_status.normal
        request_state_update()
        increment_tick()
        tick(event)
        assert.is_false(companion.visible)
      end)

      it("detects research changes and applies colors", function ()
        local r, force = setup_tick_renderer()
        local ov = r.chunk_map:get(1)
        assert.is_not_nil(ov) --- @cast ov -nil

        local tick, request_state_update = r:get_tick_function()
        tick(event) -- state update: picks up research, colors overlay
        assert.is_true(ov.visible)
        assert.is_true(ov.animation.valid)

        -- Cancel research
        force.current_research = nil
        request_state_update()
        increment_tick()
        tick(event)
        assert.is_false(ov.visible)
      end)

      it("uses rainbow colors when Settings.is_rainbow_mode is true", function ()
        local r = setup_tick_renderer()
        r.color_registry:set_ingredient_color("automation-science-pack", { 1, 1, 1 }) -- White
        Settings.is_rainbow_mode = true
        local tick = r:get_tick_function()
        tick(event) -- First tick: state update and status scan
        -- Verify that colors are NOT the science pack color.
        local anim = r.chunk_map:get(1).animation
        assert.is_not.same({ 1, 1, 1 }, anim.color)
      end)

      it("handles switching rainbow mode on/off", function ()
        local r = setup_tick_renderer()
        r.color_registry:set_ingredient_color("automation-science-pack", { 1, 1, 1 }) -- White
        Settings.is_rainbow_mode = false
        local tick1 = r:get_tick_function()
        tick1(event)
        local anim = r.chunk_map:get(1).animation
        assert.are.same({ 1, 1, 1 }, anim.color)

        Settings.is_rainbow_mode = true
        local tick2 = r:get_tick_function()
        event.tick = event.tick + 30 -- force state update
        tick2(event)
        -- Should now be something from the rainbow, not White.
        assert.is_not.same({ 1, 1, 1 }, anim.color)
      end)

      -- -------------------------------------------------------------------
      describe("player view filtering", function ()
        -- At zoom=1, 640x480, player at (0,0):
        --   f = 64, half_vw = ceil(10) = 10, half_vh = ceil(7.5) = 8
        --   chunk_right = floor((10 + 6) * 0.03125) = floor(0.5) = 0
        -- So chunk x=1 (world x=32..63) is outside the view.

        it("skips all overlays when player is in chart mode", function ()
          local r = setup_tick_renderer()
          local player = _G.game.players[1]
          player.render_mode = defines.render_mode.chart

          r:get_tick_function()(event)

          -- Overlay should not be made visible in chart mode
          assert.is_false(r.chunk_map:get(1).visible)
        end)

        it("excludes labs outside the player's chunk range", function ()
          local r = setup_tick_renderer({ x = 32 })

          r:get_tick_function()(event)

          -- Lab at x=32 is in chunk 1, outside view range [-1, 0]
          assert.is_false(r.chunk_map:get(1).visible)
        end)

        it("includes labs inside the player's chunk range", function ()
          local r = setup_tick_renderer()

          r:get_tick_function()(event)

          -- Lab at x=0 is in chunk 0, inside view range [-1, 0]
          assert.is_true(r.chunk_map:get(1).visible)
        end)

        it("wider view at lower zoom includes previously-out-of-range labs", function ()
          local r = setup_tick_renderer({ x = 32 })
          -- Lab at x=32 (chunk 1) is outside at zoom=1 but inside at zoom=0.25:
          --   f = 16, half_vw = ceil(40) = 40, chunk_right = floor(46 * 0.03125) = 1
          local player = _G.game.players[1]
          player.zoom = 0.25

          r:get_tick_function()(event)

          assert.is_true(r.chunk_map:get(1).visible)
        end)
      end)

      describe("multiplayer", function ()
        it("updates overlay visibility per force research state", function ()
          local r = make_renderer()
          local force1 = make_force(1)
          local force2 = make_force(2)
          force2.current_research = nil

          _G.game.is_multiplayer = function () return true end
          r:render_overlay_for_lab(make_entity(1, 1, 0, 0, force1))
          r:render_overlay_for_lab(make_entity(2, 1, 2, 0, force2))
          add_connected_player_at(1, force1, 1, 0, 0)
          add_connected_player_at(2, force2, 1, 0, 0)

          local tick = r:get_tick_function()
          tick(event)

          local ov1 = r.chunk_map:get(1)
          local ov2 = r.chunk_map:get(2)
          assert.is_not_nil(ov1) --- @cast ov1 -nil
          assert.is_not_nil(ov2) --- @cast ov2 -nil
          assert.is_true(ov1.visible)
          assert.is_false(ov2.visible)
        end)

        it("update_zoom_reach aggregates furthest game view across connected players", function ()
          local r = make_renderer()
          local force = make_force(1)

          _G.game.is_multiplayer = function () return true end
          local p1 = add_connected_player_at(1, force, 1, 0, 0)
          p1.zoom_limits.furthest_game_view = { zoom = 0.5 }
          p1.display_resolution = { width = 640, height = 480 }

          local _, _, update_zoom_reach = r:get_tick_function()
          assert.are.equal(26, r.chunk_map.max_reach_x)

          local p2 = add_connected_player_at(2, force, 1, 0, 0)
          p2.zoom_limits.furthest_game_view = { zoom = 0.5 }
          p2.display_resolution = { width = 1280, height = 720 }

          update_zoom_reach()
          assert.are.equal(46, r.chunk_map.max_reach_x)
        end)

        it("skips chunk scan when all players are outside surface bounds", function ()
          local r = make_renderer()
          local force = make_force(1)

          _G.game.is_multiplayer = function () return true end
          add_connected_player_at(1, force, 1, 1000, 1000)
          add_connected_player_at(2, force, 1, 1200, 1200)

          r.chunk_map.surface_bounds[1] = { -10, -10, 10, 10 }
          r.chunk_map.surface_bounds_dirty[1] = nil
          r.chunk_map.data[1] = setmetatable({}, {
            __index = function ()
              error("chunk scan should be skipped when all players are outside bounds")
            end,
          })

          local tick = r:get_tick_function()
          assert.no_error(function ()
            tick(event)
          end)
        end)

        it("stores viewer coordinates per overlay from the first player who sees it", function ()
          local r = make_renderer()
          local force = make_force(1)

          _G.game.is_multiplayer = function () return true end
          r:render_overlay_for_lab(make_entity(1, 1, 0, 0, force))
          r:render_overlay_for_lab(make_entity(2, 1, 100, 0, force))

          add_connected_player_at(1, force, 1, 0, 0)
          add_connected_player_at(2, force, 1, 100, 0)

          local tick = r:get_tick_function()
          tick(event)

          local ov1 = r.chunk_map:get(1)
          local ov2 = r.chunk_map:get(2)
          assert.is_not_nil(ov1) --- @cast ov1 -nil
          assert.is_not_nil(ov2) --- @cast ov2 -nil
          assert.are.equal(0, ov1.viewer_x)
          assert.are.equal(0, ov1.viewer_y)
          assert.are.equal(100, ov2.viewer_x)
          assert.are.equal(0, ov2.viewer_y)
        end)
      end)
    end)

    -- -------------------------------------------------------------------
    describe("color update", function ()
      it("updates animation.color for visible overlays", function ()
        local r = setup_tick_renderer()
        local ov = r.chunk_map:get(1)

        local written = false
        local mock_anim = setmetatable({}, {
          __index = { valid = true, visible = true },
          __newindex = function (t, k, v)
            if k == "color" then written = true end
            rawset(t, k, v)
          end,
        })
        ov.animation = mock_anim --[[@as LuaRenderObject]]

        r:get_tick_function()(event)
        assert.is_true(written)
      end)

      it("uses stride: updates only 1/N overlays per tick when many overlays exist", function ()
        -- Create 3 overlays
        local r = setup_tick_renderer({ n_overlays = 3 })

        local colored = {}
        for i = 1, 3 do
          local idx = i
          local ov = r.chunk_map:get(i)
          local anim = setmetatable({}, {
            __index = { valid = true, visible = true },
            __newindex = function (t, k, v)
              if k == "color" then colored[#colored + 1] = idx end
              rawset(t, k, v)
            end,
          })
          ov.animation = anim --[[@as LuaRenderObject]]
        end

        -- With only 3 overlays, current_interval=1, so all should be updated each tick.
        local tick = r:get_tick_function()
        tick(event) -- first call: state update + color update
        assert.are.equal(3, #colored)
      end)
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
        _G.game.tick = 0
        event.tick = 0
        local r = setup_tick_renderer()
        Settings.color_pattern_duration = 3

        local tick = r:get_tick_function()
        -- starts with cf_calls = 0
        tick(event) -- tick=0, epoch=0: calls choose_random(prev_index, rng) once. (epoch=0 has no prev_index)
        assert.are.equal(1, cf_calls)

        increment_tick() -- tick=1
        tick(event)      -- color: tick=1, elapsed=1
        increment_tick() -- tick=2
        tick(event)      -- color: tick=2, elapsed=2
        increment_tick() -- tick=3
        tick(event)      -- tick=3, epoch=1:
        -- Advances naturally, so it uses current color_function_index as prev_index.
        -- Does NOT call ColorFunctions.choose_random for prev_index.
        -- Calls choose_random(prev_index, rng) once for current state.
        assert.are.equal(2, cf_calls)
      end)
    end)

    -- -------------------------------------------------------------------
    describe("deterministic animation", function ()
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

      it("reconstructs phase deterministically from tick 0", function ()
        local r = setup_tick_renderer()
        Settings.color_pattern_duration = 180
        _G.game.tick = 180 * 10 + 42 -- Epoch 10, offset 42
        event.tick = _G.game.tick

        r:get_tick_function()(event)

        local phase1 = captured_phase
        assert.is_not_nil(phase1)

        -- Re-run with a fresh tick function at the same tick
        captured_phase = nil
        r:get_tick_function()(event)
        assert.are.equal(phase1, captured_phase)
      end)

      it("updates state correctly across epoch boundaries", function ()
        local r = setup_tick_renderer()
        Settings.color_pattern_duration = 10
        _G.game.tick = 0
        event.tick = _G.game.tick
        local tick = r:get_tick_function()

        tick(event) -- Tick 0: epoch 0 start
        local phase0 = captured_phase
        assert.is_not_nil(phase0)

        -- Advance to the start of epoch 1 (tick 10)
        for _ = 1, 10 do increment_tick() end
        tick(event)
        local phase10 = captured_phase
        assert.is_not_nil(phase10)

        -- In the new O(1) design, phase10 is independent of phase0's trajectory.
        -- We just verify that it changed to a new deterministic value.
        assert.are_not.equal(phase0, phase10)
      end)

      it("is independent of when the tick function was created", function ()
        local r = setup_tick_renderer()
        Settings.color_pattern_duration = 10
        _G.game.tick = 25
        event.tick = _G.game.tick

        -- Create tick function at tick 25
        r:get_tick_function()(event)
        local phase_a = captured_phase

        -- Create tick function at tick 0, run it until 25
        _G.game.tick = 0
        event.tick = _G.game.tick
        local tick = r:get_tick_function()
        for _ = 1, 25 do increment_tick() end
        tick(event)
        local phase_b = captured_phase

        assert.are.equal(phase_a, phase_b)
      end)
    end)

    -- -------------------------------------------------------------------
    describe("request_state_update", function ()
      it("forces state update on next tick call", function ()
        local r, force = setup_tick_renderer()
        local ov = r.chunk_map:get(1)
        assert.is_not_nil(ov) --- @cast ov -nil

        local tick, request_state_update = r:get_tick_function()
        tick(event) -- initial state update, overlay becomes visible
        assert.is_true(ov.visible)

        -- Cancel research and request state update
        force.current_research = nil
        request_state_update()
        increment_tick()
        tick(event)

        -- Overlay should become hidden
        assert.is_false(ov.visible)
      end)
    end)
  end)
end)
