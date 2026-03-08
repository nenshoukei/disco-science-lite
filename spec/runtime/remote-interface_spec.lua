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
  end)

  -- -------------------------------------------------------------------
  describe("registerLab", function ()
    it("registers the lab with animation and scale", function ()
      RemoteInterface.functions.registerLab("my-lab", { animation = "my-anim", scale = 2 })
      local settings = lab_reg:get_overlay_settings("my-lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("my-anim", settings.animation)
      assert.are.equal(2, settings.scale)
    end)

    it("defaults animation to nil when omitted", function ()
      RemoteInterface.functions.registerLab("my-lab", { scale = 1 })
      local settings = lab_reg:get_overlay_settings("my-lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.is_nil(settings.animation)
    end)

    it("defaults scale to nil when omitted", function ()
      RemoteInterface.functions.registerLab("my-lab", { animation = "my-anim" })
      local settings = lab_reg:get_overlay_settings("my-lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.is_nil(settings.scale)
    end)

    it("queues the call when not bound and applies it after bind_storage", function ()
      --- @diagnostic disable-next-line: missing-fields
      RemoteInterface.bind_storage({})
      RemoteInterface.functions.registerLab("my-lab", { animation = "my-anim", scale = 2 })
      -- Not applied yet
      assert.is_nil(lab_reg:get_overlay_settings("my-lab"))
      -- Bind storage — queued call should be replayed
      RemoteInterface.bind_storage({ color_registry = color_reg, lab_registry = lab_reg })
      local settings = lab_reg:get_overlay_settings("my-lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("my-anim", settings.animation)
      assert.are.equal(2, settings.scale)
    end)

    -- -------------------------------------------------------------------
    describe("validation", function ()
      it("errors when lab_name is not a string", function ()
        assert.has_error(function ()
          --- @diagnostic disable-next-line: param-type-mismatch
          RemoteInterface.functions.registerLab(123, { animation = "my-anim" })
        end)
      end)

      it("errors when lab_name is an empty string", function ()
        assert.has_error(function ()
          RemoteInterface.functions.registerLab("", { animation = "my-anim" })
        end)
      end)

      it("errors when settings is not a table", function ()
        assert.has_error(function ()
          --- @diagnostic disable-next-line: param-type-mismatch
          RemoteInterface.functions.registerLab("my-lab", "not-a-table")
        end)
      end)

      it("errors when settings is nil", function ()
        assert.has_error(function ()
          RemoteInterface.functions.registerLab("my-lab", nil --[[@as any]])
        end)
      end)

      it("errors when settings.animation is an empty string", function ()
        assert.has_error(function ()
          --- @diagnostic disable-next-line: param-type-mismatch
          RemoteInterface.functions.registerLab("my-lab", { animation = "" })
        end)
      end)

      it("errors when settings.animation is not a string", function ()
        assert.has_error(function ()
          --- @diagnostic disable-next-line: assign-type-mismatch
          RemoteInterface.functions.registerLab("my-lab", { animation = 123 })
        end)
      end)

      it("errors when settings.scale is zero", function ()
        assert.has_error(function ()
          RemoteInterface.functions.registerLab("my-lab", { scale = 0 })
        end)
      end)

      it("errors when settings.scale is negative", function ()
        assert.has_error(function ()
          RemoteInterface.functions.registerLab("my-lab", { scale = -1 })
        end)
      end)

      it("errors when settings.scale is not a number", function ()
        assert.has_error(function ()
          --- @diagnostic disable-next-line: assign-type-mismatch
          RemoteInterface.functions.registerLab("my-lab", { scale = "big" })
        end)
      end)

      it("errors immediately even when not bound", function ()
        --- @diagnostic disable-next-line: missing-fields
        RemoteInterface.bind_storage({})
        assert.has_error(function ()
          --- @diagnostic disable-next-line: param-type-mismatch
          RemoteInterface.functions.registerLab(123, { animation = "my-anim" })
        end)
      end)
    end)
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
