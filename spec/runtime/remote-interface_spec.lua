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
    it("updates scale and calls rebuild callback", function ()
      local called = false
      RemoteInterface.bind_rebuild_callback(function () called = true end)
      RemoteInterface.functions.setLabScale("lab", 3)

      local settings = lab_reg:get_overlay_settings("lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal(3, settings.scale)
      assert.is_true(called)
    end)

    it("queues calls when not bound and applies after bind_storage", function ()
      --- @diagnostic disable-next-line: missing-fields
      RemoteInterface.bind_storage({})
      local called = false
      RemoteInterface.bind_rebuild_callback(function () called = true end)

      RemoteInterface.functions.setLabScale("lab", 3)
      assert.is_nil(lab_reg:get_overlay_settings("lab"))
      assert.is_false(called)

      RemoteInterface.bind_storage({ color_registry = color_reg, lab_registry = lab_reg })
      assert.are.equal(3, lab_reg:get_overlay_settings("lab").scale)
      assert.is_true(called)
    end)

    describe("validation", function ()
      it("errors for invalid lab_name or scale", function ()
        --- @diagnostic disable-next-line: param-type-mismatch
        assert.has_error(function () RemoteInterface.functions.setLabScale(123, 1) end)
        assert.has_error(function () RemoteInterface.functions.setLabScale("", 1) end)
        assert.has_error(function () RemoteInterface.functions.setLabScale("lab", 0) end)
        assert.has_error(function () RemoteInterface.functions.setLabScale("lab", -1) end)
        --- @diagnostic disable-next-line: param-type-mismatch
        assert.has_error(function () RemoteInterface.functions.setLabScale("lab", "big") end)
      end)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("setIngredientColor", function ()
    it("sets color using indexed or named format", function ()
      RemoteInterface.functions.setIngredientColor("indexed", { 0.1, 0.2, 0.3 })
      local c1 = color_reg:get_ingredient_color("indexed")
      assert.is_not_nil(c1) --- @cast c1 -nil
      assert.are.equal(0.1, c1.r)

      RemoteInterface.functions.setIngredientColor("named", { r = 0.4, g = 0.5, b = 0.6 })
      local c2 = color_reg:get_ingredient_color("named")
      assert.is_not_nil(c2) --- @cast c2 -nil
      assert.are.equal(0.4, c2.r)
    end)

    it("queues calls and applies them later", function ()
      --- @diagnostic disable-next-line: missing-fields
      RemoteInterface.bind_storage({})
      RemoteInterface.functions.setIngredientColor("custom", { 0.5, 0.6, 0.7 })
      assert.is_nil(color_reg:get_ingredient_color("custom"))

      RemoteInterface.bind_storage({ color_registry = color_reg, lab_registry = lab_reg })
      assert.are.equal(0.5, color_reg:get_ingredient_color("custom").r)
    end)

    describe("validation", function ()
      it("errors for invalid arguments", function ()
        --- @diagnostic disable-next-line: param-type-mismatch
        assert.has_error(function () RemoteInterface.functions.setIngredientColor(123, { 0, 0, 0 }) end)
        assert.has_error(function () RemoteInterface.functions.setIngredientColor("", { 0, 0, 0 }) end)
        --- @diagnostic disable-next-line: param-type-mismatch
        assert.has_error(function () RemoteInterface.functions.setIngredientColor("p", "red") end)
        assert.has_error(function () RemoteInterface.functions.setIngredientColor("p", { 0.1, 0.2 }) end)
        assert.has_error(function () RemoteInterface.functions.setIngredientColor("p", { r = 0.1, g = 0.2 }) end)
      end)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("getIngredientColor", function ()
    it("returns color or nil correctly", function ()
      RemoteInterface.functions.setIngredientColor("pack", { 0.91, 0.16, 0.20 })
      assert.is_not_nil(RemoteInterface.functions.getIngredientColor("pack"))
      assert.is_nil(RemoteInterface.functions.getIngredientColor("unknown"))

      --- @diagnostic disable-next-line: missing-fields
      RemoteInterface.bind_storage({})
      assert.is_nil(RemoteInterface.functions.getIngredientColor("pack"))
    end)

    describe("validation", function ()
      it("errors for invalid name", function ()
        --- @diagnostic disable-next-line: param-type-mismatch
        assert.has_error(function () RemoteInterface.functions.getIngredientColor(123) end)
        assert.has_error(function () RemoteInterface.functions.getIngredientColor("") end)
      end)
    end)
  end)
end)
