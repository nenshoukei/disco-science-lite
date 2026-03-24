local CommandHelpers = require("scripts.runtime.command.command-helpers")

local SHOWCASE_WIDTH = 128 --[[$CHUNK_SIZE * 4]]

commands.add_command(
  "ds-showcase",
  "Set up showcase of all labs.",
  function (event)
    local player = game.get_player(event.player_index)
    if not player then return end

    local surface = player.surface
    CommandHelpers.setup_test_surface(surface)

    --- Use "spidertron" technology for research
    local tech = CommandHelpers.set_current_research(player.force, "spidertron")

    --- @type LuaEntityPrototype[]
    local lab_prototypes = {}
    --- @type table<string, number>
    local lab_priorities = {
      lab    = 99999,
      biolab = 99998,
    }

    for _, proto in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "lab" } })) do
      lab_prototypes[#lab_prototypes + 1] = proto
      if not lab_priorities[proto.name] then
        local inputs = {}
        if proto.lab_inputs then
          for _, ing in ipairs(proto.lab_inputs) do
            inputs[ing] = true
          end
        end

        local researchable = true
        for _, ing in pairs(tech.research_unit_ingredients) do
          if not inputs[ing] then
            researchable = false
            break
          end
        end

        --- researchable, many inputs > researchable, fewer inputs > unresearchable, many inputs > unresearchable, fewer inputs
        lab_priorities[proto.name] = (researchable and 1000 or 0) + table_size(proto.lab_inputs)
      end
    end

    table.sort(lab_prototypes, function (a, b)
      return lab_priorities[a.name] > lab_priorities[b.name]
    end)

    local top_offsets = {
      ["pressure-lab"] = 3,
    }
    local x = 0
    local y = 0
    for _, proto in ipairs(lab_prototypes) do
      x = x + proto.tile_width / 2
      y = y + proto.tile_height / 2 + (top_offsets[proto.name] or 0)
      while x < SHOWCASE_WIDTH do
        local lab = surface.create_entity({
          name = proto.name,
          position = { x = x, y = y },
          force = player.force,
          raise_built = true,
        })
        assert(lab, "Failed to create lab entity: " .. proto.name)

        CommandHelpers.fill_lab_entity_with_ingredients(lab)

        x = x + proto.tile_width
      end
      x = 0
      y = y + proto.tile_height / 2 + 1
    end
  end
)
