local RemoteInterface = require("scripts.runtime.remote-interface")
local ColorRegistry = require("scripts.runtime.color-registry")
local LabRegistry = require("scripts.runtime.lab-registry")

describe("RemoteInterface", function ()
  --- @type DiscoScienceStorage
  local empty_storage = {}

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

    it("defaults scale to nil when omitted", function ()
      RemoteInterface.functions.registerLab("my-lab", { animation = "my-anim" })
      local settings = lab_reg:get_overlay_settings("my-lab")
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.is_nil(settings.scale)
    end)

    it("does nothing when not bound", function ()
      RemoteInterface.bind_storage(empty_storage)
      assert.no_error(function ()
        RemoteInterface.functions.registerLab("my-lab", { animation = "my-anim" })
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

    it("does nothing when not bound", function ()
      RemoteInterface.bind_storage(empty_storage)
      assert.no_error(function ()
        RemoteInterface.functions.setLabScale("lab", 3)
      end)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("setIngredientColor", function ()
    it("sets the color for a registered ingredient", function ()
      RemoteInterface.functions.setIngredientColor("automation-science-pack", { 0.1, 0.2, 0.3 })
      local color = color_reg:get_ingredient_color("automation-science-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.1, color.r)
      assert.are.equal(0.2, color.g)
      assert.are.equal(0.3, color.b)
    end)

    it("registers a color for a previously unknown ingredient", function ()
      RemoteInterface.functions.setIngredientColor("custom-pack", { 0.5, 0.6, 0.7 })
      local color = color_reg:get_ingredient_color("custom-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.5, color.r)
    end)

    it("does nothing when not bound", function ()
      RemoteInterface.bind_storage(empty_storage)
      RemoteInterface.functions.setIngredientColor("custom-pack", { 0, 0, 0 }) -- should not error
    end)
  end)

  -- -------------------------------------------------------------------
  describe("getIngredientColor", function ()
    it("returns the color for a registered ingredient", function ()
      local color = RemoteInterface.functions.getIngredientColor("automation-science-pack")
      assert.is_not_nil(color)
    end)

    it("returns nil for an unregistered ingredient", function ()
      local color = RemoteInterface.functions.getIngredientColor("unknown-pack")
      assert.is_nil(color)
    end)

    it("returns nil when not bound", function ()
      RemoteInterface.bind_storage(empty_storage)
      local color = RemoteInterface.functions.getIngredientColor("automation-science-pack")
      assert.is_nil(color)
    end)
  end)
end)
