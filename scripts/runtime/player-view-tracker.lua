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

local VIEW_RECT_MARGIN = 6 -- tiles

--- The chunk range visible to a single player.
--- @class PlayerView
--- @field [1] boolean Whether the view is currently active (player connected and not in chart mode). (PV_VALID)
--- @field [2] number Surface index. (PV_SURFACE)
--- @field [3] number Chunk left boundary. (PV_LEFT)
--- @field [4] number Chunk top boundary. (PV_TOP)
--- @field [5] number Chunk right boundary. (PV_RIGHT)
--- @field [6] number Chunk bottom boundary. (PV_BOTTOM)

-- PlayerView field indices (also exported as module constants).
local PV_VALID = 1   -- boolean: whether the view is currently active
local PV_SURFACE = 2 -- Surface index
local PV_LEFT = 3    -- Chunk left boundary
local PV_TOP = 4     -- Chunk top boundary
local PV_RIGHT = 5   -- Chunk right boundary
local PV_BOTTOM = 6  -- Chunk bottom boundary

-- Export field indices for callers that index into the view table directly.
PlayerViewTracker.PV_VALID = PV_VALID
PlayerViewTracker.PV_SURFACE = PV_SURFACE
PlayerViewTracker.PV_LEFT = PV_LEFT
PlayerViewTracker.PV_TOP = PV_TOP
PlayerViewTracker.PV_RIGHT = PV_RIGHT
PlayerViewTracker.PV_BOTTOM = PV_BOTTOM

--- Constructor.
---
--- @return PlayerViewTracker
function PlayerViewTracker.new()
  --- @class PlayerViewTracker
  --- @field view PlayerView
  --- @field force LuaForce|nil
  --- @field position MapPositionTuple
  local self = {
    view = { false, 0, 0, 0, 0, 0 }, -- [PV_VALID], [PV_SURFACE], [PV_LEFT], [PV_TOP], [PV_RIGHT], [PV_BOTTOM]
    force = nil,
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
    self.view[PV_VALID] = false
    return
  end

  local player = players[1]
  if player.render_mode == RENDER_MODE_CHART then
    self.view[PV_VALID] = false
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
    pos_x - half_view_width - VIEW_RECT_MARGIN,
    pos_y - half_view_height - VIEW_RECT_MARGIN,
    pos_x + half_view_width + VIEW_RECT_MARGIN,
    pos_y + half_view_height + VIEW_RECT_MARGIN,
  }
  local chunk_left, chunk_top, chunk_right, chunk_bottom = rect_to_chunk_range(view_rect)

  local view = self.view
  view[PV_VALID] = true
  view[PV_SURFACE] = player.surface_index
  view[PV_LEFT] = chunk_left
  view[PV_TOP] = chunk_top
  view[PV_RIGHT] = chunk_right
  view[PV_BOTTOM] = chunk_bottom
end

return PlayerViewTracker
