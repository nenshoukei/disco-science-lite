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
      ["cryolab"] = 1,
    }
    local x = 0
    local y = 0
    for _, proto in ipairs(lab_prototypes) do
      local width = math.max(proto.tile_width, 1)
      local height = math.max(proto.tile_height, 1)

      y = y + (top_offsets[proto.name] or 0)
      while x < SHOWCASE_WIDTH do
        local lab = surface.create_entity({
          name = proto.name,
          position = { x = x + width / 2, y = y + height / 2 },
          force = player.force,
          raise_built = true,
        })
        assert(lab, "Failed to create lab entity: " .. proto.name)
        CommandHelpers.fill_lab_entity_with_ingredients(lab)
        x = x + width
      end
      x = 0
      y = y + height + 1
    end
  end
)

local MEGA_WIDTH = 320 --[[$CHUNK_SIZE * 10]]
local MEGA_HEIGHT = 320 --[[$CHUNK_SIZE * 10]]

commands.add_command(
  "ds-showcase2",
  "Set up showcase of vanilla labs in mega-base. Usage: /ds-showcase2 [gap:integer=0]",
  function (event)
    local player = game.get_player(event.player_index)
    if not player then return end

    local gap = event.parameter and event.parameter ~= "" and tonumber(event.parameter) or 0

    local surface = player.surface
    CommandHelpers.setup_test_surface(surface)

    --- Use "spidertron" technology for research
    CommandHelpers.set_current_research(player.force, "spidertron")

    local proto = prototypes.entity["lab"]
    local x = 0
    local y = 0
    local width = math.max(proto.tile_width, 1)
    local height = math.max(proto.tile_height, 1)
    while y < MEGA_HEIGHT do
      while x < MEGA_WIDTH do
        local lab = surface.create_entity({
          name = proto.name,
          position = { x = x + width / 2, y = y + height / 2 },
          force = player.force,
        })
        assert(lab, "Failed to create lab entity: " .. proto.name)
        CommandHelpers.fill_lab_entity_with_ingredients(lab)
        x = x + width + gap
      end
      x = 0
      y = y + height + gap
    end
  end
)
