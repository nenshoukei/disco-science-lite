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
    RemoteInterface.bind_registries(color_reg, lab_reg)
    RemoteInterface.bind_rebuild_callback(nil --[[@as fun()]])
  end)

  -- -------------------------------------------------------------------
  describe("setLabScale", function ()
    it("updates scale and calls rebuild callback", function ()
      local called = false
      RemoteInterface.bind_rebuild_callback(function () called = true end)
      RemoteInterface.functions.setLabScale("lab", 3)

      local registration = lab_reg:get_registration("lab")
      assert.is_not_nil(registration) --- @cast registration -nil
      assert.are.equal(3, registration.scale)
      assert.is_true(called)
    end)

    it("writes to the scale_overrides table", function ()
      RemoteInterface.functions.setLabScale("lab", 3)
      assert.are.equal(3, lab_reg.scale_overrides["lab"])
    end)

    it("queues calls when not bound and applies after bind_registries", function ()
      RemoteInterface.bind_registries(nil, nil)
      local called = false
      RemoteInterface.bind_rebuild_callback(function () called = true end)

      RemoteInterface.functions.setLabScale("lab", 3)
      assert.is_nil(lab_reg:get_registration("lab"))
      assert.is_false(called)

      RemoteInterface.bind_registries(color_reg, lab_reg)
      assert.are.equal(3, lab_reg:get_registration("lab").scale)
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

    it("sets multiple colors via array", function ()
      RemoteInterface.functions.setIngredientColor("multi", { { 0.1, 0.2, 0.3 }, { 0.4, 0.5, 0.6 } })
      local colors = color_reg:get_ingredient_colors("multi")
      assert.is_not_nil(colors) --- @cast colors -nil
      assert.are.equal(2, #colors)
      assert.are.equal(0.1, colors[1].r)
      assert.are.equal(0.4, colors[2].r)
    end)

    it("writes to the color_overrides table", function ()
      RemoteInterface.functions.setIngredientColor("custom", { 0.1, 0.2, 0.3 })
      assert.is_not_nil(color_reg.overrides["custom"])
    end)

    it("queues calls and applies them later", function ()
      RemoteInterface.bind_registries(nil, nil)
      RemoteInterface.functions.setIngredientColor("custom", { 0.5, 0.6, 0.7 })
      assert.is_nil(color_reg:get_ingredient_color("custom"))

      RemoteInterface.bind_registries(color_reg, lab_reg)
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
        assert.has_error(function () RemoteInterface.functions.setIngredientColor("p", {}) end)
      end)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("getIngredientColor", function ()
    it("returns first color or nil correctly", function ()
      RemoteInterface.functions.setIngredientColor("pack", { 0.91, 0.16, 0.20 })
      assert.is_not_nil(RemoteInterface.functions.getIngredientColor("pack"))
      assert.is_nil(RemoteInterface.functions.getIngredientColor("unknown"))

      RemoteInterface.bind_registries(nil, nil)
      assert.is_nil(RemoteInterface.functions.getIngredientColor("pack"))
    end)

    it("returns only the first color when multiple colors are registered", function ()
      RemoteInterface.functions.setIngredientColor("multi", { { 0.1, 0.2, 0.3 }, { 0.4, 0.5, 0.6 } })
      local color = RemoteInterface.functions.getIngredientColor("multi")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.1, color.r)
    end)

    describe("validation", function ()
      it("errors for invalid name", function ()
        --- @diagnostic disable-next-line: param-type-mismatch
        assert.has_error(function () RemoteInterface.functions.getIngredientColor(123) end)
        assert.has_error(function () RemoteInterface.functions.getIngredientColor("") end)
      end)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("getIngredientColors", function ()
    it("returns all colors or nil correctly", function ()
      RemoteInterface.functions.setIngredientColor("pack", { 0.91, 0.16, 0.20 })
      local colors = RemoteInterface.functions.getIngredientColors("pack")
      assert.is_not_nil(colors) --- @cast colors -nil
      assert.are.equal(1, #colors)
      assert.is_nil(RemoteInterface.functions.getIngredientColors("unknown"))

      RemoteInterface.bind_registries(nil, nil)
      assert.is_nil(RemoteInterface.functions.getIngredientColors("pack"))
    end)

    it("returns all colors for multi-color ingredients", function ()
      RemoteInterface.functions.setIngredientColor("multi", { { 0.1, 0.2, 0.3 }, { 0.4, 0.5, 0.6 } })
      local colors = RemoteInterface.functions.getIngredientColors("multi")
      assert.is_not_nil(colors) --- @cast colors -nil
      assert.are.equal(2, #colors)
      assert.are.equal(0.1, colors[1].r)
      assert.are.equal(0.4, colors[2].r)
    end)

    describe("validation", function ()
      it("errors for invalid name", function ()
        --- @diagnostic disable-next-line: param-type-mismatch
        assert.has_error(function () RemoteInterface.functions.getIngredientColors(123) end)
        assert.has_error(function () RemoteInterface.functions.getIngredientColors("") end)
      end)
    end)
  end)
end)
