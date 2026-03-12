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
      local t = PlayerViewTracker.new(make_default_player())
      assert.is_false(t.view[ 1 --[[$PV_VALID]] ])
    end)

    it("stores the player", function ()
      local player = make_default_player()
      local t = PlayerViewTracker.new(player)
      assert.are.equal(player, t.player)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("update", function ()
    describe("when player is in chart mode", function ()
      it("sets view valid=false", function ()
        local t = PlayerViewTracker.new(make_player(defines.render_mode.chart, 1, 0, 0, 1, 640, 480))
        t:update()
        assert.is_false(t.view[ 1 --[[$PV_VALID]] ])
      end)
    end)

    describe("when player is active", function ()
      it("sets view valid=true", function ()
        local t = PlayerViewTracker.new(make_default_player())
        t:update()
        assert.is_true(t.view[ 1 --[[$PV_VALID]] ])
      end)

      it("sets view surface to player surface_index", function ()
        local t = PlayerViewTracker.new(make_player(defines.render_mode.game, 3, 0, 0, 1, 640, 480))
        t:update()
        assert.are.equal(3, t.view[ 2 --[[$PV_SURFACE]] ])
      end)

      it("mutates view in-place", function ()
        local t = PlayerViewTracker.new(make_default_player())
        local original_view = t.view
        t:update()
        assert.are.equal(original_view, t.view) -- same table reference
      end)

      it("computes chunk bounds that include player position", function ()
        -- Player at world (0,0), zoom=1, 640x480 → view covers several chunks around origin.
        local t = PlayerViewTracker.new(make_player(defines.render_mode.game, 1, 0, 0, 1, 640, 480))
        t:update()
        assert.is_true(t.view[ 1 --[[$PV_VALID]] ])
        assert.is_true(t.view[ 3 --[[$PV_LEFT]] ] <= 0)
        assert.is_true(t.view[ 4 --[[$PV_TOP]] ] <= 0)
        assert.is_true(t.view[ 5 --[[$PV_RIGHT]] ] >= 0)
        assert.is_true(t.view[ 6 --[[$PV_BOTTOM]] ] >= 0)
      end)

      it("chunk range is wider at lower zoom", function ()
        local t1 = PlayerViewTracker.new(make_player(defines.render_mode.game, 1, 0, 0, 1.0, 640, 480))
        t1:update()

        local t2 = PlayerViewTracker.new(make_player(defines.render_mode.game, 1, 0, 0, 0.5, 640, 480))
        t2:update()

        local width1 = t1.view[ 5 --[[$PV_RIGHT]] ] - t1.view[ 3 --[[$PV_LEFT]] ]
        local width2 = t2.view[ 5 --[[$PV_RIGHT]] ] - t2.view[ 3 --[[$PV_LEFT]] ]
        assert.is_true(width2 >= width1)
      end)
    end)

    describe("valid→invalid transition", function ()
      it("clears valid when player enters chart mode after being active", function ()
        local player = make_default_player()
        local t = PlayerViewTracker.new(player)
        t:update()
        assert.is_true(t.view[ 1 --[[$PV_VALID]] ])
        t.player = make_player(defines.render_mode.chart, 1, 0, 0, 1, 640, 480)
        t:update()
        assert.is_false(t.view[ 1 --[[$PV_VALID]] ])
      end)
    end)
  end)
end)
