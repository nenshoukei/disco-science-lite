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
