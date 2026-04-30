local LabControl = require("scripts.runtime.control.lab-control")
local CommandHelpers = require("scripts.runtime.command.command-helpers")
local Settings = require("scripts.shared.settings")
local consts = require("scripts.shared.consts")
local table_merge = require("scripts.shared.utils").table_merge
--- @module "e2e.factorio-test.def"

describe("LabOverlayRenderer", function ()
  --- @type LabOverlayRenderer
  local renderer
  --- @type LuaSurface
  local surface
  --- @type LuaPlayer
  local player

  before_each(function ()
    renderer = LabControl.get_renderer()
    assert(renderer, "LabOverlayRenderer is not initialized")
    player = game.players[1]
    surface = player.surface
    CommandHelpers.setup_test_surface(surface)
  end)

  test("renders overlay for vanilla lab", function ()
    local lab = surface.create_entity({
      name = "lab",
      position = { x = 0, y = 0 },
      force = game.forces.player,
    })
    assert(lab, "lab entity is not created")

    local overlay = renderer.chunk_map:get(lab.unit_number)
    assert(overlay, "overlay is not rendered")
    assert(overlay.entity == lab, "overlay.entity is not lab entity")
    assert(overlay.animation.valid, "overlay.animation is not valid")
    assert(overlay.animation.animation == consts.LAB_OVERLAY_ANIMATION_NAME, "overlay.animation name mismatch")
    assert(overlay.animation.target.entity == lab, "overlay.animation.target is not lab entity")
    assert(renderer.chunk_map.entries[lab.unit_number], "chunk_map.entries not added")
    assert(renderer.chunk_map.data[surface.index][0][0][1] == overlay, "chunk_map.data is not updated")
  end)

  test("removes overlay when lab is destroyed", function ()
    local lab = surface.create_entity({
      name = "lab",
      position = { x = 0, y = 0 },
      force = game.forces.player,
    })
    assert(lab, "lab entity is not created")
    lab.destroy()

    after_ticks(1, function ()
      assert(next(renderer.chunk_map.entries) == nil, "chunk_map.entries is not empty after destroy")
      assert(next(renderer.chunk_map.data) == nil, "chunk_map.data is not empty after destroy")
      local objects = rendering.get_all_objects(consts.MOD_NAME)
      assert(#objects == 0, "rendering objects remain after destroy")
    end)
  end)

  test("tracks overlays in correct chunks for multiple labs", function ()
    -- Create labs in different chunks: (0,0), (1,0), (0,1)
    local lab1 = surface.create_entity({ name = "lab", position = { x = 0, y = 0 }, force = player.force })
    local lab2 = surface.create_entity({ name = "lab", position = { x = 40, y = 0 }, force = player.force })
    local lab3 = surface.create_entity({ name = "lab", position = { x = 0, y = 40 }, force = player.force })
    assert(lab1, "lab1 entity is not created")
    assert(lab2, "lab2 entity is not created")
    assert(lab3, "lab3 entity is not created")

    assert(table_size(renderer.chunk_map.entries) == 3, "Expected 3 overlays, got " .. table_size(renderer.chunk_map.entries))
    assert(renderer.chunk_map:get(lab1.unit_number), "overlay for lab1 not found")
    assert(renderer.chunk_map:get(lab2.unit_number), "overlay for lab2 not found")
    assert(renderer.chunk_map:get(lab3.unit_number), "overlay for lab3 not found")

    local entry1 = renderer.chunk_map.entries[lab1.unit_number]
    local entry2 = renderer.chunk_map.entries[lab2.unit_number]
    local entry3 = renderer.chunk_map.entries[lab3.unit_number]
    assert(entry1 and entry1.chunk_x == 0 and entry1.chunk_y == 0, "lab1 not in chunk (0,0)")
    assert(entry2 and entry2.chunk_x == 1 and entry2.chunk_y == 0, "lab2 not in chunk (1,0)")
    assert(entry3 and entry3.chunk_x == 0 and entry3.chunk_y == 1, "lab3 not in chunk (0,1)")

    lab1.destroy()
    lab2.destroy()
    lab3.destroy()

    after_ticks(1, function ()
      assert(next(renderer.chunk_map.entries) == nil, "chunk_map.entries is not empty after destroy")
      assert(next(renderer.chunk_map.data) == nil, "chunk_map.data is not empty after destroy")
      local objects = rendering.get_all_objects(consts.MOD_NAME)
      assert(#objects == 0, "rendering objects remain after destroy")
    end)
  end)

  test("updates chunk_map when lab is teleported", function ()
    local lab = surface.create_entity({ name = "lab", position = { x = 0, y = 0 }, force = player.force })
    assert(lab, "lab entity is not created")

    local entry_before = renderer.chunk_map.entries[lab.unit_number]
    assert(entry_before, "chunk_map.entries not found before teleport")
    assert(
      entry_before.chunk_x == 0 and entry_before.chunk_y == 0,
      "Expected initial chunk (0,0), got (" .. entry_before.chunk_x .. "," .. entry_before.chunk_y .. ")"
    )

    -- Teleport to chunk (1,1): position (40, 40) -> floor(40/32) = 1
    lab.teleport({ 40, 40 }, nil, true)

    after_ticks(1, function ()
      local entry_after = renderer.chunk_map.entries[lab.unit_number]
      assert(entry_after, "chunk_map.entries not found after teleport")
      assert(
        entry_after.chunk_x == 1 and entry_after.chunk_y == 1,
        "Expected teleported chunk (1,1), got (" .. entry_after.chunk_x .. "," .. entry_after.chunk_y .. ")"
      )

      -- Old chunk (0,0) should be gone
      local surface_chunks = renderer.chunk_map.data[surface.index]
      assert(not (surface_chunks and surface_chunks[0] and surface_chunks[0][0]), "Old chunk (0,0) still exists in chunk_map")

      lab.destroy()
    end)

    after_ticks(2, function ()
      assert(next(renderer.chunk_map.entries) == nil, "chunk_map.entries is not empty after destroy")
      assert(next(renderer.chunk_map.data) == nil, "chunk_map.data is not empty after destroy")
      local objects = rendering.get_all_objects(consts.MOD_NAME)
      assert(#objects == 0, "rendering objects remain after destroy")
    end)
  end)

  test("renders overlay on a different surface", function ()
    local map_gen_settings = table_merge(game.default_map_gen_settings, {
      width = 32,
      height = 32,
      no_enemies_mode = true,
    })
    local new_surface = game.create_surface(consts.NAME_PREFIX .. "test-surface", map_gen_settings)
    CommandHelpers.clear_surface(new_surface)

    local lab = new_surface.create_entity({ name = "lab", position = { x = 0, y = 0 }, force = player.force })
    assert(lab, "lab entity is not created on new surface")
    assert(renderer.chunk_map:get(lab.unit_number), "overlay not created for lab on new surface")
    assert(
      renderer.chunk_map.entries[lab.unit_number].surface_index == new_surface.index,
      "overlay surface_index mismatch"
    )

    new_surface.clear()

    after_ticks(1, function ()
      assert(next(renderer.chunk_map.entries) == nil, "chunk_map.entries is not empty after surface clear")
      assert(next(renderer.chunk_map.data) == nil, "chunk_map.data is not empty after surface clear")
      local objects = rendering.get_all_objects(consts.MOD_NAME)
      assert(#objects == 0, "rendering objects remain after surface clear")

      game.delete_surface(new_surface)
    end)
  end)

  test("applies color to overlay when research is active", function ()
    local force = player.force
    local lab = surface.create_entity({ name = "lab", position = { x = 0, y = 0 }, force = force })
    assert(lab, "lab entity not created")
    CommandHelpers.fill_lab_entity_with_ingredients(lab)
    CommandHelpers.set_current_research(force, "automation")
    player.teleport({ x = 0, y = 0 }, surface)
    player.zoom = 1.0

    after_ticks(consts.STATE_UPDATE_INTERVAL + 1, function ()
      local overlay = renderer.chunk_map:get(lab.unit_number)
      assert(overlay, "overlay not found for lab")
      assert(
        overlay.visible,
        "overlay is not visible (entity.status=" .. tostring(lab.status)
        .. ", current_research=" .. tostring(force.current_research and force.current_research.name) .. ")"
      )
      local color = overlay.animation.color
      assert(color and (color.r > 0 or color.g > 0 or color.b > 0), "overlay animation color is not set")

      force.cancel_current_research()
    end)
  end)

  test("renders overlays for all lab prototypes", function ()
    local lab_prototypes = prototypes.get_entity_filtered({ { filter = "type", type = "lab" } })
    local created_labs = {} --- @type LuaEntity[]
    local x = 0
    for _, proto in pairs(lab_prototypes) do
      local lab = surface.create_entity({
        name = proto.name,
        position = { x = x, y = 0 },
        force = player.force,
      })
      assert(lab, "Failed to create lab entity: " .. proto.name)
      created_labs[#created_labs + 1] = lab
      x = x + proto.tile_width
    end

    for i = 1, #created_labs do
      local lab = created_labs[i]
      local lab_name = lab.name
      local is_excluded = renderer.lab_registry:is_excluded(lab_name)
      local has_registration = renderer.lab_registry:get_registration(lab_name) ~= nil
      local should_have_overlay = not is_excluded and (has_registration or Settings.is_fallback_enabled)
      if should_have_overlay then
        local overlay = renderer.chunk_map:get(lab.unit_number)
        assert(overlay, "overlay not found for lab: " .. lab_name)
        assert(overlay.animation.valid, "overlay animation not valid for lab: " .. lab_name)
        assert(renderer.chunk_map.entries[lab.unit_number], "chunk_map entry not found for lab: " .. lab_name)
      else
        assert(not renderer.chunk_map:get(lab.unit_number), "excluded lab should not have overlay: " .. lab_name)
      end
    end

    for i = 1, #created_labs do
      created_labs[i].destroy()
    end

    after_ticks(1, function ()
      assert(next(renderer.chunk_map.entries) == nil, "chunk_map.entries is not empty after destroy")
      assert(next(renderer.chunk_map.data) == nil, "chunk_map.data is not empty after destroy")
      local objects = rendering.get_all_objects(consts.MOD_NAME)
      assert(#objects == 0, "rendering objects remain after destroy")
    end)
  end)
end)
