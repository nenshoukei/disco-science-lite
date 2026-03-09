--- @diagnostic disable: deprecated
local RemoteInterface = require("scripts.runtime.remote-interface")
local ColorRegistry = require("scripts.runtime.color-registry")
local LabRegistry = require("scripts.runtime.lab-registry")

describe("RemoteInterface", function ()
  --- @type ColorRegistry
  local color_reg
  --- @type LabRegistry
  local lab_reg

  before_each(function ()
    color_reg = ColorRegistry.new()
    lab_reg = LabRegistry.new()
    RemoteInterface.bind_storage({
      color_registry = color_reg,
      lab_registry = lab_reg,
    })
    RemoteInterface.bind_rebuild_callback(nil --[[@as fun()]])
  end)

  -- -------------------------------------------------------------------
  describe("setLabScale", function ()
    it("updates scale for a registered lab", function ()
      RemoteInterface.functions.setLabScale("lab", 3)
      local settings = lab_reg:get_overlay_settings("lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal(3, settings.scale)
    end)

    it("auto-registers an unknown lab with the given scale", function ()
      RemoteInterface.functions.setLabScale("new-lab", 5)
      local settings = lab_reg:get_overlay_settings("new-lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal(5, settings.scale)
    end)

    it("calls the rebuild callback after updating scale", function ()
      local called = false
      RemoteInterface.bind_rebuild_callback(function () called = true end)
      RemoteInterface.functions.setLabScale("lab", 3)
      assert.is_true(called)
    end)

    it("does not call the rebuild callback when it has not been bound", function ()
      -- rebuild_callback is nil (reset in before_each); setLabScale must not error
      assert.no_error(function ()
        RemoteInterface.functions.setLabScale("lab", 3)
      end)
    end)

    it("does not call the rebuild callback for queued calls replayed by bind_storage", function ()
      --- @diagnostic disable-next-line: missing-fields
      RemoteInterface.bind_storage({})
      local called = false
      -- Bind callback BEFORE bind_storage so it is set when pending calls are replayed
      RemoteInterface.bind_rebuild_callback(function () called = true end)
      RemoteInterface.functions.setLabScale("lab", 3)
      -- Queued, not yet applied — callback must not have been called
      assert.is_false(called)
      -- Replay pending calls via bind_storage
      RemoteInterface.bind_storage({ color_registry = color_reg, lab_registry = lab_reg })
      -- Callback IS called during replay because it was already bound
      assert.is_true(called)
    end)

    it("queues the call when not bound and applies it after bind_storage", function ()
      --- @diagnostic disable-next-line: missing-fields
      RemoteInterface.bind_storage({})
      RemoteInterface.functions.setLabScale("lab", 3)
      -- Not applied yet
      assert.is_nil(lab_reg:get_overlay_settings("lab"))
      -- Bind storage — queued call should be replayed
      RemoteInterface.bind_storage({ color_registry = color_reg, lab_registry = lab_reg })
      local settings = lab_reg:get_overlay_settings("lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal(3, settings.scale)
    end)

    -- -------------------------------------------------------------------
    describe("validation", function ()
      it("errors when lab_name is not a string", function ()
        assert.has_error(function ()
          --- @diagnostic disable-next-line: param-type-mismatch
          RemoteInterface.functions.setLabScale(123, 1)
        end)
      end)

      it("errors when lab_name is an empty string", function ()
        assert.has_error(function ()
          RemoteInterface.functions.setLabScale("", 1)
        end)
      end)

      it("errors when scale is zero", function ()
        assert.has_error(function ()
          RemoteInterface.functions.setLabScale("lab", 0)
        end)
      end)

      it("errors when scale is negative", function ()
        assert.has_error(function ()
          RemoteInterface.functions.setLabScale("lab", -1)
        end)
      end)

      it("errors when scale is not a number", function ()
        assert.has_error(function ()
          --- @diagnostic disable-next-line: param-type-mismatch
          RemoteInterface.functions.setLabScale("lab", "big")
        end)
      end)

      it("errors immediately even when not bound", function ()
        --- @diagnostic disable-next-line: missing-fields
        RemoteInterface.bind_storage({})
        assert.has_error(function ()
          --- @diagnostic disable-next-line: param-type-mismatch
          RemoteInterface.functions.setLabScale(123, 1)
        end)
      end)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("setIngredientColor", function ()
    it("sets the color for an ingredient using indexed format", function ()
      RemoteInterface.functions.setIngredientColor("automation-science-pack", { 0.1, 0.2, 0.3 })
      local color = color_reg:get_ingredient_color("automation-science-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.1, color.r)
      assert.are.equal(0.2, color.g)
      assert.are.equal(0.3, color.b)
    end)

    it("sets the color for an ingredient using named format", function ()
      RemoteInterface.functions.setIngredientColor("automation-science-pack", { r = 0.4, g = 0.5, b = 0.6 })
      local color = color_reg:get_ingredient_color("automation-science-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.4, color.r)
      assert.are.equal(0.5, color.g)
      assert.are.equal(0.6, color.b)
    end)

    it("registers a color for a previously unknown ingredient", function ()
      RemoteInterface.functions.setIngredientColor("custom-pack", { 0.5, 0.6, 0.7 })
      local color = color_reg:get_ingredient_color("custom-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.5, color.r)
    end)

    it("queues the call when not bound and applies it after bind_storage", function ()
      --- @diagnostic disable-next-line: missing-fields
      RemoteInterface.bind_storage({})
      RemoteInterface.functions.setIngredientColor("custom-pack", { 0.5, 0.6, 0.7 })
      -- Not applied yet
      assert.is_nil(color_reg:get_ingredient_color("custom-pack"))
      -- Bind storage — queued call should be replayed
      RemoteInterface.bind_storage({ color_registry = color_reg, lab_registry = lab_reg })
      local color = color_reg:get_ingredient_color("custom-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.5, color.r)
    end)

    -- -------------------------------------------------------------------
    describe("validation", function ()
      it("errors when name is not a string", function ()
        assert.has_error(function ()
          --- @diagnostic disable-next-line: param-type-mismatch
          RemoteInterface.functions.setIngredientColor(123, { 0, 0, 0 })
        end)
      end)

      it("errors when name is an empty string", function ()
        assert.has_error(function ()
          RemoteInterface.functions.setIngredientColor("", { 0, 0, 0 })
        end)
      end)

      it("errors when color is not a table", function ()
        assert.has_error(function ()
          --- @diagnostic disable-next-line: param-type-mismatch
          RemoteInterface.functions.setIngredientColor("custom-pack", "red")
        end)
      end)

      it("errors when indexed color is missing a component", function ()
        assert.has_error(function ()
          RemoteInterface.functions.setIngredientColor("custom-pack", { 0.1, 0.2 } --[[@as any]])
        end)
      end)

      it("errors when named color is missing a component", function ()
        assert.has_error(function ()
          RemoteInterface.functions.setIngredientColor("custom-pack", { r = 0.1, g = 0.2 } --[[@as any]])
        end)
      end)

      it("errors immediately even when not bound", function ()
        --- @diagnostic disable-next-line: missing-fields
        RemoteInterface.bind_storage({})
        assert.has_error(function ()
          --- @diagnostic disable-next-line: param-type-mismatch
          RemoteInterface.functions.setIngredientColor(123, { 0, 0, 0 })
        end)
      end)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("getIngredientColor", function ()
    it("returns the color for a registered ingredient", function ()
      RemoteInterface.functions.setIngredientColor("automation-science-pack", { 0.91, 0.16, 0.20 })
      local color = RemoteInterface.functions.getIngredientColor("automation-science-pack")
      assert.is_not_nil(color)
    end)

    it("returns nil for an unregistered ingredient", function ()
      local color = RemoteInterface.functions.getIngredientColor("unknown-pack")
      assert.is_nil(color)
    end)

    it("returns nil when not bound", function ()
      --- @diagnostic disable-next-line: missing-fields
      RemoteInterface.bind_storage({})
      local color = RemoteInterface.functions.getIngredientColor("automation-science-pack")
      assert.is_nil(color)
    end)

    -- -------------------------------------------------------------------
    describe("validation", function ()
      it("errors when name is not a string", function ()
        assert.has_error(function ()
          --- @diagnostic disable-next-line: param-type-mismatch
          RemoteInterface.functions.getIngredientColor(123)
        end)
      end)

      it("errors when name is an empty string", function ()
        assert.has_error(function ()
          RemoteInterface.functions.getIngredientColor("")
        end)
      end)
    end)
  end)
end)
