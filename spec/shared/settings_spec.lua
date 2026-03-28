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

    it("reads color_saturation from global and scales by 0.01", function ()
      _G.settings.global[ "mks-dsl-color-saturation" --[[$COLOR_SATURATION_NAME]] ] = { value = 50 }
      Settings.reload()
      assert.are.equal(0.5, Settings.color_saturation)
    end)

    it("reads color_brightness from global and scales by 0.01", function ()
      _G.settings.global[ "mks-dsl-color-brightness" --[[$COLOR_BRIGHTNESS_NAME]] ] = { value = 75 }
      Settings.reload()
      assert.are.equal(0.75, Settings.color_brightness)
    end)

    it("reads color_pattern_duration from global", function ()
      _G.settings.global[ "mks-dsl-color-pattern-duration" --[[$COLOR_PATTERN_DURATION_NAME]] ] = { value = 360 }
      Settings.reload()
      assert.are.equal(360, Settings.color_pattern_duration)
    end)

    it("reads color_update_preset from global", function ()
      _G.settings.global[ "mks-dsl-color-update-preset" --[[$COLOR_UPDATE_PRESET_NAME]] ] = { value = "performance" }
      Settings.reload()
      assert.are.equal("performance", Settings.color_update_preset)
    end)

    it("derives color_update_budget from color_update_preset", function ()
      _G.settings.global[ "mks-dsl-color-update-preset" --[[$COLOR_UPDATE_PRESET_NAME]] ] = { value = "smooth" }
      Settings.reload()
      assert.are.equal(500, Settings.color_update_budget)

      _G.settings.global[ "mks-dsl-color-update-preset" --[[$COLOR_UPDATE_PRESET_NAME]] ] = { value = "balanced" }
      Settings.reload()
      assert.are.equal(200, Settings.color_update_budget)

      _G.settings.global[ "mks-dsl-color-update-preset" --[[$COLOR_UPDATE_PRESET_NAME]] ] = { value = "performance" }
      Settings.reload()
      assert.are.equal(50, Settings.color_update_budget)
    end)

    it("derives color_update_max_per_call from color_update_preset", function ()
      _G.settings.global[ "mks-dsl-color-update-preset" --[[$COLOR_UPDATE_PRESET_NAME]] ] = { value = "smooth" }
      Settings.reload()
      assert.are.equal(1000, Settings.color_update_max_per_call)

      _G.settings.global[ "mks-dsl-color-update-preset" --[[$COLOR_UPDATE_PRESET_NAME]] ] = { value = "balanced" }
      Settings.reload()
      assert.are.equal(500, Settings.color_update_max_per_call)

      _G.settings.global[ "mks-dsl-color-update-preset" --[[$COLOR_UPDATE_PRESET_NAME]] ] = { value = "performance" }
      Settings.reload()
      assert.are.equal(100, Settings.color_update_max_per_call)
    end)

    -- -------------------------------------------------------------------
    describe("when global is nil", function ()
      before_each(function ()
        _G.settings.global = nil
        Settings.reload()
      end)

      it("uses default color_saturation of 1.0", function ()
        assert.are.equal(1.0, Settings.color_saturation)
      end)

      it("uses default color_brightness of 1.0", function ()
        assert.are.equal(1.0, Settings.color_brightness)
      end)

      it("uses default color_pattern_duration of 180", function ()
        assert.are.equal(180 --[[$DEFAULT_COLOR_PATTERN_DURATION]], Settings.color_pattern_duration)
      end)

      it("uses default color_update_preset of 'balanced'", function ()
        assert.are.equal("balanced", Settings.color_update_preset)
      end)

      it("uses default color_update_budget of 200", function ()
        assert.are.equal(200, Settings.color_update_budget)
      end)

      it("uses default color_update_max_per_call of 500", function ()
        assert.are.equal(500, Settings.color_update_max_per_call)
      end)
    end)

    -- -------------------------------------------------------------------
    describe("when startup is nil", function ()
      it("returns early without changing any field", function ()
        Settings.reload()
        local prev_fallback = Settings.is_fallback_enabled

        _G.settings.startup = nil
        -- Change a global value to confirm global fields also remain unchanged
        _G.settings.global[ "mks-dsl-color-saturation" --[[$COLOR_SATURATION_NAME]] ] = { value = 0 }
        Settings.reload()

        assert.are.equal(prev_fallback, Settings.is_fallback_enabled)
        assert.are_not.equal(0.0, Settings.color_saturation)
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
