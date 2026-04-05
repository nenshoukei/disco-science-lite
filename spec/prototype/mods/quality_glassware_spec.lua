local Helper = require("spec.helper")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")

_G.mods["quality_glassware"] = "1.0.0"
local Mod = require("scripts.prototype.mods.quality_glassware")

describe("mods/quality_glassware", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeColorRegistry.reset()
    _G.mods["quality_glassware"] = "1.0.0"
    _G.data.raw["tool"] = {}
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    it("registers color for tool with matching icon filename", function ()
      _G.data.raw["tool"]["my-green-pack"] = ({
        type = "tool",
        name = "my-green-pack",
        icon = "__quality_glassware__/graphics/icons/cone_inverted_clear_green.png",
      }) --[[@as data.ToolPrototype]]

      Mod.on_data_final_fixes()

      assert.are.same({ 0.35, 0.98, 0.38 }, PrototypeColorRegistry.registered_colors["my-green-pack"])
    end)

    it("registers color from icons list when icon field is absent", function ()
      _G.data.raw["tool"]["my-blue-pack"] = ({
        type = "tool",
        name = "my-blue-pack",
        icons = {
          { icon = "__quality_glassware__/graphics/icons/sphere_double_clear_blue.png" },
        },
      }) --[[@as data.ToolPrototype]]

      Mod.on_data_final_fixes()

      assert.are.same({ 0.22, 0.35, 0.98 }, PrototypeColorRegistry.registered_colors["my-blue-pack"])
    end)

    it("uses first matching icon from icons list", function ()
      _G.data.raw["tool"]["my-pack"] = ({
        type = "tool",
        name = "my-pack",
        icons = {
          { icon = "__quality_glassware__/graphics/icons/cube_empty.png" },
          { icon = "__quality_glassware__/graphics/icons/cone_inverted_clear_red.png" },
        },
      }) --[[@as data.ToolPrototype]]

      Mod.on_data_final_fixes()

      assert.are.same({ 0.75, 0.75, 0.75 }, PrototypeColorRegistry.registered_colors["my-pack"])
    end)

    it("overwrites already registered tool", function ()
      local existing_color = { 0.5, 0.5, 0.5 }
      PrototypeColorRegistry.set("already-registered", existing_color)

      _G.data.raw["tool"]["already-registered"] = ({
        type = "tool",
        name = "already-registered",
        icon = "__quality_glassware__/graphics/icons/cone_inverted_clear_red.png",
      }) --[[@as data.ToolPrototype]]

      Mod.on_data_final_fixes()

      assert.are.same({ 1.00, 0.29, 0.29 }, PrototypeColorRegistry.registered_colors["already-registered"])
    end)

    it("skips tools with non-Quality-Glassware icon", function ()
      _G.data.raw["tool"]["vanilla-pack"] = ({
        type = "tool",
        name = "vanilla-pack",
        icon = "__base__/graphics/icons/automation-science-pack.png",
      }) --[[@as data.ToolPrototype]]

      Mod.on_data_final_fixes()

      assert.is_nil(PrototypeColorRegistry.registered_colors["vanilla-pack"])
    end)

    it("skips tools with no icon", function ()
      _G.data.raw["tool"]["no-icon-pack"] = ({
        type = "tool",
        name = "no-icon-pack",
      }) --[[@as data.ToolPrototype]]

      Mod.on_data_final_fixes()

      assert.is_nil(PrototypeColorRegistry.registered_colors["no-icon-pack"])
    end)

    -- -------------------------------------------------------------------
    describe("color mapping (COLORS)", function ()
      --- @type { color: string, icon: string, expected: ColorTuple }[]
      local cases = {
        { color = "empty",  icon = "__quality_glassware__/graphics/icons/cube_empty.png",                 expected = { 0.75, 0.75, 0.75 } },
        { color = "red",    icon = "__quality_glassware__/graphics/icons/cube_clear_red.png",             expected = { 1.00, 0.29, 0.29 } },
        { color = "green",  icon = "__quality_glassware__/graphics/icons/cone_inverted_clear_green.png",  expected = { 0.35, 0.98, 0.38 } },
        { color = "black",  icon = "__quality_glassware__/graphics/icons/cube_clear_black.png",           expected = { 0.31, 0.31, 0.31 } },
        { color = "cyan",   icon = "__quality_glassware__/graphics/icons/sphere_double_clear_cyan.png",   expected = { 0.29, 0.94, 1.00 } },
        { color = "purple", icon = "__quality_glassware__/graphics/icons/cone_inverted_clear_purple.png", expected = { 0.68, 0.31, 0.82 } },
        { color = "yellow", icon = "__quality_glassware__/graphics/icons/cube_clear_yellow.png",          expected = { 1.00, 0.88, 0.24 } },
        { color = "white",  icon = "__quality_glassware__/graphics/icons/sphere_double_clear_white.png",  expected = { 1.00, 1.00, 1.00 } },
        { color = "orange", icon = "__quality_glassware__/graphics/icons/cone_inverted_clear_orange.png", expected = { 1.00, 0.71, 0.25 } },
        { color = "pink",   icon = "__quality_glassware__/graphics/icons/cube_clear_pink.png",            expected = { 1.00, 0.33, 0.89 } },
        { color = "blue",   icon = "__quality_glassware__/graphics/icons/sphere_double_clear_blue.png",   expected = { 0.22, 0.35, 0.98 } },
        { color = "lime",   icon = "__quality_glassware__/graphics/icons/cone_inverted_clear_lime.png",   expected = { 1.00, 0.98, 0.25 } },
      }

      for i = 1, #cases do
        local case = cases[i]
        it("maps " .. case.color .. " icon to correct color", function ()
          _G.data.raw["tool"]["test-pack"] = ({
            type = "tool",
            name = "test-pack",
            icon = case.icon,
          }) --[[@as data.ToolPrototype]]

          Mod.on_data_final_fixes()

          assert.are.same(case.expected, PrototypeColorRegistry.registered_colors["test-pack"])
        end)
      end
    end)
  end)
end)
