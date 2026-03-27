local helper = require("spec.helper")
local Settings = require("scripts.shared.settings")

describe("Settings", function ()
  before_each(function ()
    helper.reset_mocks()
  end)

  -- -------------------------------------------------------------------
  describe("reload", function ()
    it("reads is_fallback_enabled from startup", function ()
      _G.settings.startup[ "mks-dsl-fallback-overlay-enabled" --[[$FALLBACK_OVERLAY_ENABLED_NAME]] ] = { value = false }
      Settings.reload()
      assert.are.equal(false, Settings.is_fallback_enabled)
    end)

    it("reads is_lab_blinking_disabled from startup", function ()
      _G.settings.startup[ "mks-dsl-lab-blinking-disabled" --[[$LAB_BLINKING_DISABLED_NAME]] ] = { value = true }
      Settings.reload()
      assert.are.equal(true, Settings.is_lab_blinking_disabled)
    end)

    it("reads is_development from startup", function ()
      _G.settings.startup[ "mks-dsl-is-development" --[[$IS_DEVELOPMENT_NAME]] ] = { value = false }
      Settings.reload()
      assert.are.equal(false, Settings.is_development)
    end)

    it("reads color_intensity from global and scales by 0.01", function ()
      _G.settings.global[ "mks-dsl-color-intensity" --[[$COLOR_INTENSITY_NAME]] ] = { value = 50 }
      Settings.reload()
      assert.are.equal(0.5, Settings.color_intensity)
    end)

    it("reads color_pattern_duration from global", function ()
      _G.settings.global[ "mks-dsl-color-pattern-duration" --[[$COLOR_PATTERN_DURATION_NAME]] ] = { value = 360 }
      Settings.reload()
      assert.are.equal(360, Settings.color_pattern_duration)
    end)

    it("reads max_updates_per_tick from global", function ()
      _G.settings.global[ "mks-dsl-max-updates-per-tick" --[[$MAX_UPDATES_PER_TICK_NAME]] ] = { value = 200 }
      Settings.reload()
      assert.are.equal(200, Settings.max_updates_per_tick)
    end)

    -- -------------------------------------------------------------------
    describe("when global is nil", function ()
      before_each(function ()
        _G.settings.global = nil
        Settings.reload()
      end)

      it("uses default color_intensity of 1.0", function ()
        assert.are.equal(1.0, Settings.color_intensity)
      end)

      it("uses default color_pattern_duration of 180", function ()
        assert.are.equal(180 --[[$DEFAULT_COLOR_PATTERN_DURATION]], Settings.color_pattern_duration)
      end)

      it("uses default max_updates_per_tick of 500", function ()
        assert.are.equal(500 --[[$DEFAULT_MAX_UPDATES_PER_TICK]], Settings.max_updates_per_tick)
      end)
    end)

    -- -------------------------------------------------------------------
    describe("when startup is nil", function ()
      it("returns early without changing any field", function ()
        Settings.reload()
        local prev_fallback = Settings.is_fallback_enabled

        _G.settings.startup = nil
        -- Change a global value to confirm global fields also remain unchanged
        _G.settings.global[ "mks-dsl-color-intensity" --[[$COLOR_INTENSITY_NAME]] ] = { value = 0 }
        Settings.reload()

        assert.are.equal(prev_fallback, Settings.is_fallback_enabled)
        assert.are_not.equal(0.0, Settings.color_intensity)
      end)
    end)

    -- -------------------------------------------------------------------
    describe("when settings global is nil", function ()
      it("returns early without changing any field", function ()
        Settings.reload()
        local prev_fallback = Settings.is_fallback_enabled

        _G.settings = nil
        Settings.reload()

        assert.are.equal(prev_fallback, Settings.is_fallback_enabled)
      end)
    end)
  end)
end)
