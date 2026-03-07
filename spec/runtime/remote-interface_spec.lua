local RemoteInterface = require("scripts.runtime.remote-interface")
local ColorRegistry = require("scripts.runtime.color-registry")
local TargetLabRegistry = require("scripts.runtime.target-lab-registry")

describe("RemoteInterface", function ()
  --- @type DiscoScienceStorage
  local empty_storage = {}

  local color_reg
  local target_lab_reg

  before_each(function ()
    color_reg = ColorRegistry.new()
    target_lab_reg = TargetLabRegistry.new()
    RemoteInterface.bind_storage({
      color_registry = color_reg,
      target_lab_registry = target_lab_reg,
    })
  end)

  -- -------------------------------------------------------------------
  describe("addTargetLab", function ()
    it("registers the lab with animation and scale", function ()
      RemoteInterface.functions.addTargetLab("my-lab", "my-anim", 2)
      local target = target_lab_reg:get("my-lab")
      assert.is_not_nil(target) --- @cast target -nil
      assert.are.equal("my-anim", target.animation)
      assert.are.equal(2, target.scale)
    end)

    it("defaults scale to 1 when omitted", function ()
      RemoteInterface.functions.addTargetLab("my-lab", "my-anim")
      local target = target_lab_reg:get("my-lab")
      assert.is_not_nil(target) --- @cast target -nil
      assert.are.equal(1, target.scale)
    end)

    it("does nothing when not bound", function ()
      RemoteInterface.bind_storage(empty_storage)
      RemoteInterface.functions.addTargetLab("my-lab", "my-anim") -- should not error
    end)
  end)

  -- -------------------------------------------------------------------
  describe("setLabScale", function ()
    it("updates scale for a registered lab", function ()
      RemoteInterface.functions.setLabScale("lab", 3)
      local target = target_lab_reg:get("lab")
      assert.is_not_nil(target) --- @cast target -nil
      assert.are.equal(3, target.scale)
    end)

    it("auto-registers an unknown lab with the given scale", function ()
      RemoteInterface.functions.setLabScale("new-lab", 5)
      local target = target_lab_reg:get("new-lab")
      assert.is_not_nil(target) --- @cast target -nil
      assert.are.equal(5, target.scale)
    end)

    it("does nothing when not bound", function ()
      RemoteInterface.bind_storage(empty_storage)
      RemoteInterface.functions.setLabScale("lab", 3) -- should not error
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
