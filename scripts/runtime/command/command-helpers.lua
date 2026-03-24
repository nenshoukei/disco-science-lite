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

--- Set the current research for the given force.
---
--- @param force ForceID
--- @param tech TechnologyID
--- @return LuaTechnology
function CommandHelpers.set_current_research(force, tech)
  local target_force = (type(force) == "string" or type(force) == "number") and game.forces[force] or force --[[@as LuaForce]]
  assert(target_force, "target force does not exist")

  local tech_name = type(tech) == "string" and tech or tech.name
  local target_tech = force.technologies[tech_name]
  assert(target_tech, "technology " .. tech_name .. " does not exist")
  target_tech.research_recursive() -- researches all prerequisites recursively
  target_tech.researched = false
  target_tech.saved_progress = 0   -- resets the progress

  -- Start research on the target technology
  force.cancel_current_research()
  local added = force.add_research(target_tech)
  assert(added, "force.add_research failed for technology " .. tech_name)

  return target_tech
end

--- Fill a lab entity with ingredients and fuel for working.
---
--- @param lab LuaEntity
function CommandHelpers.fill_lab_entity_with_ingredients(lab)
  local proto = lab.prototype

  -- Fill ingredients
  local inventory = lab.get_inventory(defines.inventory.lab_input)
  if inventory and proto.lab_inputs then
    for _, ingredient in ipairs(proto.lab_inputs) do
      inventory.insert({ name = ingredient, count = 100 })
    end
  end

  -- Fill burner fuel
  if lab.burner then
    for fuel_category in pairs(lab.burner.fuel_categories) do
      local fuel_items = prototypes.get_item_filtered({ { filter = "fuel-category", ["fuel-category"] = fuel_category } })
      for fuel in pairs(fuel_items) do
        lab.burner.inventory.insert(fuel)
      end
    end
    lab.burner.heat = lab.burner.heat_capacity
  end

  -- Fill fluid
  if proto.fluid_energy_source_prototype then
    local fluid_box = proto.fluid_energy_source_prototype.fluid_box
    local fluid = fluid_box.filter or prototypes.fluid["steam"]
    lab.insert_fluid({
      name = fluid.name,
      amount = fluid_box.volume,
      temperature = fluid.max_temperature,
    })
  end
end

return CommandHelpers
