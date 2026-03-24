local LabControl = require("scripts.runtime.control.lab-control")

commands.add_command(
  "ds-force-render",
  "Force re-render all DiscoScienceLite lab overlays.",
  function (event)
    LabControl.force_render()

    local player = game.get_player(event.player_index)
    if player then player.print("Disco Science Lite: All overlays are re-rendered.") end
  end
)
