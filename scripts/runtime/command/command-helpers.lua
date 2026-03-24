local CommandHelpers = {}

--- Clear the given surface except for electric energy interface.
--- @param surface LuaSurface
function CommandHelpers.clear_surface(surface)
  for _, entity in ipairs(surface.find_entities()) do
    if entity.name ~= "electric-energy-interface" then
      entity.destroy()
    end
  end
end

--- Set up test environment on the surface.
---
--- * Removes all entities
--- * Removes all decoratives
--- * Fills every chunks with checkerboard tiles
--- * Sets to always day
--- * Sets global electric network
--- * Creates an infinity electric energy at { -10, -10 }
---
--- @param surface LuaSurface
function CommandHelpers.setup_test_surface(surface)
  CommandHelpers.clear_surface(surface)
  surface.destroy_decoratives({})
  for chunk in surface.get_chunks() do
    if surface.is_chunk_generated(chunk) then
      surface.build_checkerboard(chunk.area)
    end
  end
  surface.always_day = true
  surface.create_global_electric_network()
  surface.create_entity({
    name = "electric-energy-interface",
    position = { x = -10, y = -10 },
    force = "player",
  })
end

return CommandHelpers
