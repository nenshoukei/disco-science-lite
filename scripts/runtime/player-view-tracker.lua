local Utils = require("scripts.shared.utils")

--- Tracks the single connected player's view state.
---
--- The `view` table is always allocated and mutated in-place, so callers can
--- capture `tracker.view` once as a closure local and always see current values.
--- Check `view[PV_VALID]` before reading any view fields.
---
--- @class PlayerViewTracker
local PlayerViewTracker = {}
PlayerViewTracker.__index = PlayerViewTracker

local ceil = math.ceil
local rect_to_chunk_range = Utils.rect_to_chunk_range
local RENDER_MODE_CHART = defines.render_mode.chart

--- The chunk range visible to a single player.
--- @class (exact) PlayerView
--- @field [1] boolean [PV_VALID]   Whether the view is currently active (player connected and not in chart mode).
--- @field [2] number  [PV_SURFACE] Surface index.
--- @field [3] number  [PV_LEFT]    Chunk left boundary.
--- @field [4] number  [PV_TOP]     Chunk top boundary.
--- @field [5] number  [PV_RIGHT]   Chunk right boundary.
--- @field [6] number  [PV_BOTTOM]  Chunk bottom boundary.

--- Constructor.
---
--- @return PlayerViewTracker
function PlayerViewTracker.new()
  --- @class PlayerViewTracker
  local self = {
    --- @type PlayerView
    view = {
      [ 1 --[[$PV_VALID]] ]   = false,
      [ 2 --[[$PV_SURFACE]] ] = 0,
      [ 3 --[[$PV_LEFT]] ]    = 0,
      [ 4 --[[$PV_TOP]] ]     = 0,
      [ 5 --[[$PV_RIGHT]] ]   = 0,
      [ 6 --[[$PV_BOTTOM]] ]  = 0,
    },
    --- @type LuaForce|nil
    force = nil,
    --- @type MapPositionTuple
    position = { 0, 0 },
  }
  return setmetatable(self, PlayerViewTracker)
end

--- Rebuild the view data from the given list of connected players.
---
--- Pass `game.connected_players` in production. In tests, pass a mock array.
--- Sets `view[PV_VALID] = false` when in multiplayer or chart mode.
---
--- @param players LuaPlayer[]
function PlayerViewTracker:update(players)
  -- This mod is single-player only. Do not update in multiplayer.
  if #players ~= 1 then
    self.view[ 1 --[[$PV_VALID]] ] = false
    return
  end

  local player = players[1]
  if player.render_mode == RENDER_MODE_CHART then
    self.view[ 1 --[[$PV_VALID]] ] = false
    return
  end

  self.force = player.force --[[@as LuaForce]]

  local player_position = player.position
  local pos_x = player_position.x
  local pos_y = player_position.y
  local self_position = self.position
  self_position[1] = pos_x
  self_position[2] = pos_y

  local f = player.zoom * 64 -- * 32 (pixels per tile) * 2 (half)
  local display_resolution = player.display_resolution
  local half_view_width = ceil(display_resolution.width / f)
  local half_view_height = ceil(display_resolution.height / f)

  local view_rect = {
    pos_x - half_view_width - 6 --[[$VIEW_RECT_MARGIN]],
    pos_y - half_view_height - 6 --[[$VIEW_RECT_MARGIN]],
    pos_x + half_view_width + 6 --[[$VIEW_RECT_MARGIN]],
    pos_y + half_view_height + 6 --[[$VIEW_RECT_MARGIN]],
  }
  local chunk_left, chunk_top, chunk_right, chunk_bottom = rect_to_chunk_range(view_rect)

  local view = self.view
  view[ 1 --[[$PV_VALID]] ] = true
  view[ 2 --[[$PV_SURFACE]] ] = player.surface_index
  view[ 3 --[[$PV_LEFT]] ] = chunk_left
  view[ 4 --[[$PV_TOP]] ] = chunk_top
  view[ 5 --[[$PV_RIGHT]] ] = chunk_right
  view[ 6 --[[$PV_BOTTOM]] ] = chunk_bottom
end

return PlayerViewTracker
