local LabControl = require("scripts.runtime.control.lab-control")

--- @param surface LuaSurface
local function clear_surface(surface)
  for _, entity in ipairs(surface.find_entities()) do
    entity.destroy()
  end
end

--- @class TestCase
--- @field name string
--- @field test fun(renderer: LabOverlayRenderer, surface: LuaSurface, player: LuaPlayer)

--- Count entries in a table.
--- @param t table
--- @return number
local function count(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

--- @type TestCase[]
local test_cases = {
  {
    name = "Renders vanilla lab overlay",
    test = function (renderer, surface)
      clear_surface(surface)

      local lab = surface.create_entity({
        name = "lab",
        position = { x = 0, y = 0 },
        force = game.forces.player,
        raise_built = true,
      })
      assert(lab, "lab entity is not created")

      local _, overlay = next(renderer.overlays)
      assert(overlay, "overlay is not rendered")
      assert(overlay.entity == lab, "overlay.entity is not lab entity")
      assert(overlay.animation.valid, "overlay.animation is not valid")
      assert(overlay.animation.animation == "mks-dsl-lab-overlay" --[[$LAB_OVERLAY_ANIMATION_NAME]], "overlay.animation is not lab overlay")
      assert(overlay.animation.target.entity == lab, "overlay.animation.target is not lab entity")

      assert(renderer.chunk_map.entries[lab.unit_number], "chunk_map.entries not added")
      assert(renderer.chunk_map.data[surface.index][0][0][1] == overlay, "chunk_map.data is not updated")

      lab.destroy({ raise_destroy = true })
    end,
  },
  {
    name = "After lab entity destroyed",
    test = function (renderer)
      assert(next(renderer.overlays) == nil, "overlays is not empty")
      assert(next(renderer.chunk_map.entries) == nil, "chunk_map.entries is not empty")
      assert(next(renderer.chunk_map.data) == nil, "chunk_map.data is not empty")

      local objects = rendering.get_all_objects("disco-science-lite" --[[$MOD_NAME]])
      assert(#objects == 0, "rendering object still remains")
    end,
  },
  {
    name = "Renders multiple labs",
    test = function (renderer, surface, player)
      clear_surface(surface)

      -- Create labs in different chunks: (0,0), (1,0), (0,1)
      local lab1 = surface.create_entity({ name = "lab", position = { x = 0, y = 0 }, force = player.force, raise_built = true })
      local lab2 = surface.create_entity({ name = "lab", position = { x = 40, y = 0 }, force = player.force, raise_built = true })
      local lab3 = surface.create_entity({ name = "lab", position = { x = 0, y = 40 }, force = player.force, raise_built = true })
      assert(lab1, "lab1 entity is not created")
      assert(lab2, "lab2 entity is not created")
      assert(lab3, "lab3 entity is not created")

      assert(count(renderer.overlays) == 3, "Expected 3 overlays, got " .. count(renderer.overlays))
      assert(renderer.overlays[lab1.unit_number], "overlay for lab1 not found")
      assert(renderer.overlays[lab2.unit_number], "overlay for lab2 not found")
      assert(renderer.overlays[lab3.unit_number], "overlay for lab3 not found")

      local entry1 = renderer.chunk_map.entries[lab1.unit_number]
      local entry2 = renderer.chunk_map.entries[lab2.unit_number]
      local entry3 = renderer.chunk_map.entries[lab3.unit_number]
      assert(entry1 and entry1.chunk_x == 0 and entry1.chunk_y == 0, "lab1 not in chunk (0,0)")
      assert(entry2 and entry2.chunk_x == 1 and entry2.chunk_y == 0, "lab2 not in chunk (1,0)")
      assert(entry3 and entry3.chunk_x == 0 and entry3.chunk_y == 1, "lab3 not in chunk (0,1)")

      lab1.destroy({ raise_destroy = true })
      lab2.destroy({ raise_destroy = true })
      lab3.destroy({ raise_destroy = true })
    end,
  },
  {
    name = "After multiple labs destroyed",
    test = function (renderer)
      assert(next(renderer.overlays) == nil, "overlays is not empty")
      assert(next(renderer.chunk_map.entries) == nil, "chunk_map.entries is not empty")
      assert(next(renderer.chunk_map.data) == nil, "chunk_map.data is not empty")

      local objects = rendering.get_all_objects("disco-science-lite" --[[$MOD_NAME]])
      assert(#objects == 0, "rendering object still remains")
    end,
  },
  {
    name = "Lab teleportation updates chunk_map",
    test = function (renderer, surface, player)
      clear_surface(surface)

      local lab = surface.create_entity({ name = "lab", position = { x = 0, y = 0 }, force = player.force, raise_built = true })
      assert(lab, "lab entity is not created")

      local entry_before = renderer.chunk_map.entries[lab.unit_number]
      assert(entry_before, "chunk_map.entries not found before teleport")
      assert(entry_before.chunk_x == 0 and entry_before.chunk_y == 0,
        "Expected initial chunk (0,0), got (" .. entry_before.chunk_x .. "," .. entry_before.chunk_y .. ")")

      -- Teleport to chunk (1,1): position (40, 40) -> floor(40/32) = 1
      lab.teleport({ 40, 40 })
      renderer:update_lab_position(lab)

      local entry_after = renderer.chunk_map.entries[lab.unit_number]
      assert(entry_after, "chunk_map.entries not found after teleport")
      assert(entry_after.chunk_x == 1 and entry_after.chunk_y == 1,
        "Expected teleported chunk (1,1), got (" .. entry_after.chunk_x .. "," .. entry_after.chunk_y .. ")")

      -- Old chunk (0,0) should be gone
      local surface_chunks = renderer.chunk_map.data[surface.index]
      assert(not (surface_chunks and surface_chunks[0] and surface_chunks[0][0]), "Old chunk (0,0) still exists in chunk_map")

      lab.destroy({ raise_destroy = true })
    end,
  },
  {
    name = "After teleported lab destroyed",
    test = function (renderer)
      assert(next(renderer.overlays) == nil, "overlays is not empty")
      assert(next(renderer.chunk_map.entries) == nil, "chunk_map.entries is not empty")
      assert(next(renderer.chunk_map.data) == nil, "chunk_map.data is not empty")

      local objects = rendering.get_all_objects("disco-science-lite" --[[$MOD_NAME]])
      assert(#objects == 0, "rendering object still remains")
    end,
  },
  {
    name = "Surface cleared removes overlays",
    test = function (renderer, surface, player)
      clear_surface(surface)

      local lab = surface.create_entity({ name = "lab", position = { x = 0, y = 0 }, force = player.force, raise_built = true })
      assert(lab, "lab entity is not created")
      assert(renderer.overlays[lab.unit_number], "overlay not created before surface clear")

      renderer:remove_overlays_on_surface(surface.index)

      assert(next(renderer.overlays) == nil, "overlays is not empty after surface cleared")
      assert(next(renderer.chunk_map.entries) == nil, "chunk_map.entries is not empty after surface cleared")
      assert(next(renderer.chunk_map.data) == nil, "chunk_map.data is not empty after surface cleared")

      local objects = rendering.get_all_objects("disco-science-lite" --[[$MOD_NAME]])
      assert(#objects == 0, "rendering objects remain after surface cleared")

      -- Lab entity still exists; clean it up without raising events (overlays already cleared).
      clear_surface(surface)
    end,
  },
  {
    name = "Sets up research for colorization test",
    test = function (renderer, surface, player)
      clear_surface(surface)
      local force = player.force --[[@as LuaForce]]

      -- Create lab at origin
      local lab = surface.create_entity({ name = "lab", position = { x = 0, y = 0 }, force = force, raise_built = true })
      assert(lab, "lab entity not created")

      -- Provide power: small-electric-pole at (2,0) covers lab at (0,0), accumulator at (4,0) supplies energy
      local pole = surface.create_entity({ name = "small-electric-pole", position = { x = 2, y = 0 }, force = force })
      local accum = surface.create_entity({ name = "accumulator", position = { x = 4, y = 0 }, force = force })
      assert(pole, "small-electric-pole not created")
      assert(accum, "accumulator not created")
      accum.energy = accum.electric_buffer_size

      -- Use automation technology for reasearch
      local target_tech = force.technologies["automation"]
      assert(target_tech, "automation technology does not exist")
      target_tech.research_recursive() -- researches all prerequisites recursively
      target_tech.researched = false

      -- Insert the required ingredients into the lab
      local inventory = lab.get_inventory(defines.inventory.lab_input)
      assert(inventory, "lab_input inventory not found")
      for j = 1, #target_tech.research_unit_ingredients do
        local ingredient = target_tech.research_unit_ingredients[j]
        inventory.insert({ name = ingredient.name, count = 100 })
      end

      -- Start research on the target technology
      force.cancel_current_research()
      local added = force.add_research(target_tech)
      assert(added, "force.add_research failed for technology " .. target_tech.name)

      -- Position the player at the lab so it is within the viewport
      player.teleport({ x = 0, y = 0 }, surface)
      player.zoom = 1.0
    end,
  },
  {
    name = "Colors are applied to overlays in viewport",
    test = function (renderer, surface, player)
      local force = player.force --[[@as LuaForce]]

      local labs = surface.find_entities_filtered({ type = "lab" })
      assert(#labs >= 1, "Expected at least 1 lab on surface")
      local lab = labs[1]

      local overlay = renderer.overlays[lab.unit_number]
      assert(overlay, "overlay not found for lab")

      -- Verify that force_state has colors computed from current_research
      local fs = renderer.force_state[lab.force_index]
      assert(fs, "force_state not initialized for this force")
      assert(fs.colors, "force_state.colors not set (research color not computed)")

      -- Verify the overlay is visible (lab is working/low_power and research is active)
      assert(overlay.visible,
        "overlay is not visible (entity.status=" .. tostring(lab.status)
        .. ", current_research=" .. tostring(force.current_research and force.current_research.name) .. ")")

      -- Verify the overlay was added to visible_overlays (state_update confirmed it in viewport)
      local found_in_visible = false
      for i = 1, #renderer.visible_overlays do
        if renderer.visible_overlays[i] == overlay then
          found_in_visible = true
          break
        end
      end
      assert(found_in_visible, "overlay not found in renderer.visible_overlays")

      -- Cleanup: cancel research, destroy all entities
      force.cancel_current_research()
      clear_surface(surface)
    end,
  },
  {
    name = "Renders all lab prototypes",
    test = function (renderer, surface, player)
      clear_surface(surface)

      local lab_prototypes = prototypes.get_entity_filtered({ { filter = "type", type = "lab" } })
      local created_labs = {} --- @type LuaEntity[]
      local x = 0
      for _, proto in pairs(lab_prototypes) do
        local lab = surface.create_entity({
          name = proto.name,
          position = { x = x, y = 0 },
          force = player.force,
          raise_built = true,
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
        local should_have_overlay = not is_excluded and (has_registration or renderer.is_fallback_enabled)
        if should_have_overlay then
          local overlay = renderer.overlays[lab.unit_number]
          assert(overlay, "overlay not found for lab: " .. lab_name)
          assert(overlay.animation.valid, "overlay animation not valid for lab: " .. lab_name)
          assert(renderer.chunk_map.entries[lab.unit_number], "chunk_map entry not found for lab: " .. lab_name)
        else
          assert(not renderer.overlays[lab.unit_number], "excluded lab should not have overlay: " .. lab_name)
        end
      end

      for i = 1, #created_labs do
        created_labs[i].destroy({ raise_destroy = true })
      end
    end,
  },
  {
    name = "After all lab prototypes destroyed",
    test = function (renderer)
      assert(next(renderer.overlays) == nil, "overlays is not empty")
      assert(next(renderer.chunk_map.entries) == nil, "chunk_map.entries is not empty")
      assert(next(renderer.chunk_map.data) == nil, "chunk_map.data is not empty")

      local objects = rendering.get_all_objects("disco-science-lite" --[[$MOD_NAME]])
      assert(#objects == 0, "rendering object still remains")
    end,
  },
}

local TEST_INTERVAL = 31 -- state update = every 30 ticks, so use 30 + 1

commands.add_command(
  "ds-test",
  "Run integration tests for Disco Science Lite. Usage: /ds-test",
  function (event)
    local player = game.get_player(event.player_index)
    if not player then return end

    local surface = player.surface
    local renderer = LabControl.get_renderer()
    if not renderer then
      log("Error: LabOverlayRenderer is not initialized.")
      return
    end

    player.print("Disco Science Lite: Running integration tests")
    clear_surface(surface)

    local n_test_cases = #test_cases
    local test_case_index = 1
    local failed_tests = {}
    script.on_nth_tick(TEST_INTERVAL, function ()
      local test_case = test_cases[test_case_index]
      local log_name = string.format("[%2d/%2d] %s", test_case_index, n_test_cases, test_case.name)
      log("⏩️ Running " .. log_name)

      local success, err = pcall(test_case.test, renderer, surface, player)
      if success then
        log("✅️ Passed  " .. log_name)
      else
        log("❌️ Failed  " .. log_name .. ": " .. err)
        table.insert(failed_tests, log_name .. ": " .. err)
      end

      if test_case_index >= #test_cases then
        player.print("Disco Science Lite: All integration tests have finished.")
        log(string.rep("-", 80))
        if #failed_tests == 0 then
          log("✅️ All " .. #test_cases .. " tests have passed.")
        else
          log("❌️ " .. #failed_tests .. " tests have failed.")
          for _, failed in ipairs(failed_tests) do
            log(failed)
          end
        end
        script.on_nth_tick(TEST_INTERVAL, nil)
      else
        test_case_index = test_case_index + 1
      end
    end)
  end
)

commands.add_command(
  "ds-force-render",
  "Force re-render all DiscoScienceLite lab overlays.",
  function (event)
    LabControl.force_render()

    local player = game.get_player(event.player_index)
    if player then player.print("Disco Science Lite: All overlays are re-rendered.") end
  end
)
