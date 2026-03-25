local CommandHelpers = require("scripts.runtime.command.command-helpers")

--- @param player LuaPlayer
--- @param tech_name string
--- @param callback fun(tech: LuaTechnology|nil, matches: LuaTechnology[]?)
local function search_tech_by_name(player, tech_name, callback)
  local technologies = player.force.technologies

  local tech = technologies[tech_name]
  if tech then return callback(tech) end

  -- Normalize "Tech Name" to "tech-name" and try it with suffix "-1"
  local normalized_tech_name = tech_name:lower():gsub("%s+", "-")
  tech = technologies[normalized_tech_name] or technologies[normalized_tech_name .. "-1"]
  if tech then return callback(tech) end

  -- Search by localised_name
  local localised_names = {} --- @type LocalisedString[]
  for name, t in pairs(technologies) do
    localised_names[name] = t.localised_name
  end
  CommandHelpers.translate_strings(player, localised_names, function (translated)
    local matched = {} --- @type LuaTechnology[]
    for name, localised in pairs(translated) do
      local normalized = localised:lower():gsub("%s+", "-")
      if normalized:find(normalized_tech_name, 1, true) then
        table.insert(matched, technologies[name])
      end
    end

    if #matched == 0 then
      callback(nil)
    elseif #matched == 1 then
      callback(matched[1])
    else
      callback(nil, matched)
    end
  end)
end

commands.add_command(
  "ds-set-tech",
  "Set the current research technology. Usage: /ds-set-tech tech-name",
  function (event)
    local player = game.get_player(event.player_index)
    if not player or not player.force then return end

    local tech_name = (event.parameter or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if tech_name == "" then
      player.print("Error: no tech-name specified")
      return
    end

    search_tech_by_name(player, tech_name, function (tech, matches)
      if not tech then
        if matches then
          player.print("There are " .. #matches .. " matches. Be more specific.")
          for _, match in ipairs(matches) do
            player.print({ "", "* ", match.name, " = ", match.localised_name })
          end
        else
          player.print("No matching technology found.")
        end
        return
      end

      CommandHelpers.set_current_research(player.force, tech)
      player.print({ "", "Research is set to ", tech.localised_name })
    end)
  end
)
