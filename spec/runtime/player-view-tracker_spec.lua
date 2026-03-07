local PlayerViewTracker = require("scripts.runtime.player-view-tracker")

--- Create a mock LuaPlayer.
--- @param render_mode defines.render_mode
--- @param surface_index number
--- @param x number
--- @param y number
--- @param zoom number
--- @param res_w number
--- @param res_h number
--- @return LuaPlayer
local function make_player(render_mode, surface_index, x, y, zoom, res_w, res_h)
  return ({
    render_mode = render_mode,
    force = { index = 1 },
    surface_index = surface_index,
    position = { x = x, y = y },
    zoom = zoom,
    display_resolution = { width = res_w, height = res_h },
  }) --[[@as LuaPlayer]]
end

--- Create a default active player (render_mode=game, surface=1, pos=(0,0), zoom=1, 640x480).
--- @return LuaPlayer
local function make_default_player()
  return make_player(defines.render_mode.game, 1, 0, 0, 1, 640, 480)
end

describe("PlayerViewTracker", function ()
  -- -------------------------------------------------------------------
  describe("new", function ()
    it("creates view with valid=false", function ()
      local t = PlayerViewTracker.new()
      assert.is_false(t.view[PlayerViewTracker.PV_VALID])
    end)

    it("creates with nil force", function ()
      local t = PlayerViewTracker.new()
      assert.is_nil(t.force)
    end)

    it("creates with position {0, 0}", function ()
      local t = PlayerViewTracker.new()
      assert.are.equal(0, t.position[1])
      assert.are.equal(0, t.position[2])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("update", function ()
    describe("when player count is not 1", function ()
      it("sets view valid=false for 0 players", function ()
        local t = PlayerViewTracker.new()
        t:update({})
        assert.is_false(t.view[PlayerViewTracker.PV_VALID])
      end)

      it("sets view valid=false for 2 players", function ()
        local t = PlayerViewTracker.new()
        t:update({ make_default_player(), make_default_player() })
        assert.is_false(t.view[PlayerViewTracker.PV_VALID])
      end)
    end)

    describe("when player is in chart mode", function ()
      it("sets view valid=false", function ()
        local t = PlayerViewTracker.new()
        t:update({ make_player(defines.render_mode.chart, 1, 0, 0, 1, 640, 480) })
        assert.is_false(t.view[PlayerViewTracker.PV_VALID])
      end)
    end)

    describe("when player is active", function ()
      it("sets view valid=true", function ()
        local t = PlayerViewTracker.new()
        t:update({ make_default_player() })
        assert.is_true(t.view[PlayerViewTracker.PV_VALID])
      end)

      it("sets view surface to player surface_index", function ()
        local t = PlayerViewTracker.new()
        t:update({ make_player(defines.render_mode.game, 3, 0, 0, 1, 640, 480) })
        assert.are.equal(3, t.view[PlayerViewTracker.PV_SURFACE])
      end)

      it("sets force on the tracker", function ()
        local t = PlayerViewTracker.new()
        local player = make_default_player()
        t:update({ player })
        assert.are.equal(player.force, t.force)
      end)

      it("mutates position in-place", function ()
        local t = PlayerViewTracker.new()
        local original_pos = t.position
        t:update({ make_player(defines.render_mode.game, 1, 16, 32, 1, 640, 480) })
        assert.are.equal(original_pos, t.position) -- same table reference
        assert.are.equal(16, t.position[1])
        assert.are.equal(32, t.position[2])
      end)

      it("mutates view in-place", function ()
        local t = PlayerViewTracker.new()
        local original_view = t.view
        t:update({ make_default_player() })
        assert.are.equal(original_view, t.view) -- same table reference
      end)

      it("computes chunk bounds that include player position", function ()
        -- Player at world (0,0), zoom=1, 640x480 → view covers several chunks around origin.
        local t = PlayerViewTracker.new()
        t:update({ make_player(defines.render_mode.game, 1, 0, 0, 1, 640, 480) })
        assert.is_true(t.view[PlayerViewTracker.PV_VALID])
        assert.is_true(t.view[PlayerViewTracker.PV_LEFT] <= 0)
        assert.is_true(t.view[PlayerViewTracker.PV_TOP] <= 0)
        assert.is_true(t.view[PlayerViewTracker.PV_RIGHT] >= 0)
        assert.is_true(t.view[PlayerViewTracker.PV_BOTTOM] >= 0)
      end)

      it("chunk range is wider at lower zoom", function ()
        local t1 = PlayerViewTracker.new()
        t1:update({ make_player(defines.render_mode.game, 1, 0, 0, 1.0, 640, 480) })

        local t2 = PlayerViewTracker.new()
        t2:update({ make_player(defines.render_mode.game, 1, 0, 0, 0.5, 640, 480) })

        local width1 = t1.view[PlayerViewTracker.PV_RIGHT] - t1.view[PlayerViewTracker.PV_LEFT]
        local width2 = t2.view[PlayerViewTracker.PV_RIGHT] - t2.view[PlayerViewTracker.PV_LEFT]
        assert.is_true(width2 >= width1)
      end)
    end)

    describe("valid→invalid transition", function ()
      it("clears valid when player disconnects after being active", function ()
        local t = PlayerViewTracker.new()
        t:update({ make_default_player() })
        assert.is_true(t.view[PlayerViewTracker.PV_VALID])
        t:update({})
        assert.is_false(t.view[PlayerViewTracker.PV_VALID])
      end)
    end)
  end)
end)
