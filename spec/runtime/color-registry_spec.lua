local ColorRegistry = require("scripts.runtime.color-registry")

--- Helper: build a mock technology with the given ingredient names.
--- @param ... string
--- @return LuaTechnology
local function make_tech(...)
  local ingredients = {}
  for i = 1, select("#", ...) do
    ingredients[i] = { name = select(i, ...) }
  end
  return ({ research_unit_ingredients = ingredients }) --[[@as LuaTechnology]]
end

--- Helper: build a mock prototypes table from a list of technologies.
--- @param techs table[]
--- @return LuaPrototypes
local function make_prototypes(techs)
  local technology = {}
  for i = 1, #techs do
    technology["tech-" .. i] = techs[i]
  end
  return ({ technology = technology }) --[[@as LuaPrototypes]]
end

--- Set up mock mod_data for load_prototype_colors tests.
--- @param colors table<string, ColorTuple>|nil nil to remove mod_data
local function set_mod_data(colors)
  if colors then
    _G.prototypes.mod_data[ "mks-dsl-ingredient-colors" --[[$INGREDIENT_COLORS_MOD_DATA_NAME]] ] = ({ data = colors }) --[[@as LuaModData]]
  else
    _G.prototypes.mod_data[ "mks-dsl-ingredient-colors" --[[$INGREDIENT_COLORS_MOD_DATA_NAME]] ] = nil
  end
end

describe("ColorRegistry", function ()
  -- -------------------------------------------------------------------
  describe("new", function ()
    it("creates an instance with empty ingredient colors", function ()
      local r = ColorRegistry.new()
      -- ingredient_colors starts empty; colors are loaded via load_prototype_colors()
      local color = r:get_ingredient_color("automation-science-pack")
      assert.is_nil(color)
    end)

    it("accepts an overrides table", function ()
      local overrides = { ["custom-pack"] = { 0.5, 0.6, 0.7 } }
      local r = ColorRegistry.new(overrides)
      assert.are.equal(overrides, r.overrides)
    end)

    it("defaults overrides to an empty table when not provided", function ()
      local r = ColorRegistry.new()
      assert.are.same({}, r.overrides)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("get_ingredient_color", function ()
    it("returns nil for unknown ingredient", function ()
      local r = ColorRegistry.new()
      assert.is_nil(r:get_ingredient_color("unknown-pack"))
    end)

    it("returns a color struct with r,g,b fields", function ()
      local r = ColorRegistry.new()
      r:set_ingredient_color("automation-science-pack", { 0.91, 0.16, 0.20 })
      local color = r:get_ingredient_color("automation-science-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.is_number(color.r)
      assert.is_number(color.g)
      assert.is_number(color.b)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("set_ingredient_color", function ()
    it("sets a new color for an existing ingredient", function ()
      local r = ColorRegistry.new()
      r:set_ingredient_color("automation-science-pack", { 0.1, 0.2, 0.3 })
      local color = r:get_ingredient_color("automation-science-pack")
      assert.is_not_nil(color)
      --- @cast color -nil
      assert.are.equal(0.1, color.r)
      assert.are.equal(0.2, color.g)
      assert.are.equal(0.3, color.b)
    end)

    it("registers a color for a previously unknown ingredient", function ()
      local r = ColorRegistry.new()
      r:set_ingredient_color("custom-pack", { 0.5, 0.6, 0.7 })
      local color = r:get_ingredient_color("custom-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.5, color.r)
    end)

    it("accepts named color fields (r,g,b)", function ()
      local r = ColorRegistry.new()
      r:set_ingredient_color("custom-pack", { r = 0.1, g = 0.2, b = 0.3 })
      local color = r:get_ingredient_color("custom-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.1, color.r)
    end)

    it("writes to the overrides table", function ()
      local overrides = {}
      local r = ColorRegistry.new(overrides)
      r:set_ingredient_color("custom-pack", { 0.1, 0.2, 0.3 })
      assert.is_not_nil(overrides["custom-pack"])
    end)

    it("instances are independent from each other", function ()
      local r1 = ColorRegistry.new()
      local r2 = ColorRegistry.new()
      r1:set_ingredient_color("automation-science-pack", { 0, 0, 0 })
      -- r2 should not be affected by r1's changes
      local color = r2:get_ingredient_color("automation-science-pack")
      assert.is_nil(color)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("load_prototype_colors", function ()
    before_each(function ()
      set_mod_data(nil)
    end)

    it("does nothing when mod_data prototype is absent", function ()
      local r = ColorRegistry.new()
      assert.no_error(function ()
        r:load_prototype_colors()
      end)
      assert.is_nil(r:get_ingredient_color("automation-science-pack"))
    end)

    it("loads colors from mod_data", function ()
      set_mod_data({ ["automation-science-pack"] = { 0.91, 0.16, 0.20 } })
      local r = ColorRegistry.new()
      r:load_prototype_colors()
      local color = r:get_ingredient_color("automation-science-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.91, color.r)
    end)

    it("loads a copy of the prototype data (not a reference)", function ()
      set_mod_data({ ["pack"] = { 0.1, 0.2, 0.3 } })
      local r = ColorRegistry.new()
      r:load_prototype_colors()
      local proto_data = _G.prototypes.mod_data
        [ "mks-dsl-ingredient-colors" --[[$INGREDIENT_COLORS_MOD_DATA_NAME]] ].data
      assert.are_not.equal(proto_data["pack"], r.ingredient_colors["pack"])
    end)

    it("replaces previously loaded colors on re-load", function ()
      set_mod_data({ ["pack"] = { 0.5, 0.5, 0.5 } })
      local r = ColorRegistry.new()
      r:load_prototype_colors()
      set_mod_data({ ["other-pack"] = { 0.1, 0.1, 0.1 } })
      r:load_prototype_colors()
      -- old color is gone, new color is present
      assert.is_nil(r:get_ingredient_color("pack"))
      assert.is_not_nil(r:get_ingredient_color("other-pack"))
    end)

    it("re-applies runtime overrides on top of prototype data", function ()
      set_mod_data({ ["proto-pack"] = { 0.1, 0.2, 0.3 } })
      local overrides = {}
      local r = ColorRegistry.new(overrides)
      r:set_ingredient_color("override-pack", { 0.9, 0.8, 0.7 })
      -- Simulate re-load (e.g. on_configuration_changed): prototype data changes
      set_mod_data({ ["proto-pack"] = { 0.4, 0.5, 0.6 }, ["override-pack"] = { 0.0, 0.0, 0.0 } })
      r:load_prototype_colors()
      -- Prototype color is updated
      local proto_color = r:get_ingredient_color("proto-pack")
      assert.is_not_nil(proto_color) --- @cast proto_color -nil
      assert.are.equal(0.4, proto_color.r)
      -- Override wins over new prototype value
      local override_color = r:get_ingredient_color("override-pack")
      assert.is_not_nil(override_color) --- @cast override_color -nil
      assert.are.equal(0.9, override_color.r)
    end)

    it("applies overrides even when mod_data is absent", function ()
      local overrides = {}
      local r = ColorRegistry.new(overrides)
      r:set_ingredient_color("custom-pack", { 0.5, 0.5, 0.5 })
      r:load_prototype_colors() -- no mod_data
      local color = r:get_ingredient_color("custom-pack")
      assert.is_not_nil(color)  --- @cast color -nil
      assert.are.equal(0.5, color.r)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("get_colors_for_research", function ()
    it("returns colors for registered ingredients as an array of tuples", function ()
      local r = ColorRegistry.new()
      r:set_ingredient_color("automation-science-pack", { 0.91, 0.16, 0.20 })
      r:set_ingredient_color("logistic-science-pack", { 0.29, 0.97, 0.31 })
      local tech = make_tech("automation-science-pack", "logistic-science-pack")
      local colors = r:get_colors_for_research(tech)
      assert.are.equal(2, #colors)
      assert.are.equal(0.91, colors[1][1])
      assert.are.equal(0.16, colors[1][2])
      assert.are.equal(0.20, colors[1][3])
      assert.are.equal(0.29, colors[2][1])
      assert.are.equal(0.97, colors[2][2])
      assert.are.equal(0.31, colors[2][3])
    end)

    it("skips unregistered ingredients", function ()
      local r = ColorRegistry.new()
      local tech = make_tech("automation-science-pack", "unknown-pack")
      local colors = r:get_colors_for_research(tech)
      assert.are.equal(1, #colors)
    end)

    it("returns default colors when no ingredient is registered", function ()
      local r = ColorRegistry.new()
      local tech = make_tech("unknown-pack")
      local colors = r:get_colors_for_research(tech)
      assert.are.same(ColorRegistry.default_research_colors, colors)
    end)

    it("returns default colors for a technology with no ingredients", function ()
      local r = ColorRegistry.new()
      local tech = make_tech()
      local colors = r:get_colors_for_research(tech)
      assert.are.same(ColorRegistry.default_research_colors, colors)
    end)

    it("returns tuples (indexed arrays)", function ()
      local r = ColorRegistry.new()
      local tech = make_tech("automation-science-pack")
      local colors = r:get_colors_for_research(tech)
      assert.is_number(colors[1][1])
      assert.is_number(colors[1][2])
      assert.is_number(colors[1][3])
    end)

    it("returns new tuples independent of the registry", function ()
      local r = ColorRegistry.new()
      r:set_ingredient_color("custom-pack", { 1.0, 1.0, 1.0 })
      local tech = make_tech("custom-pack")
      local colors = r:get_colors_for_research(tech)
      colors[1][1] = 99 -- mutate returned tuple
      local colors2 = r:get_colors_for_research(tech)
      assert.are_not.equal(99, colors2[1][1])
    end)

    describe("with intensity", function ()
      it("defaults to 1.0 when intensity is omitted", function ()
        local r = ColorRegistry.new()
        r:set_ingredient_color("custom-pack", { 0.5, 0.5, 0.5 })
        local tech = make_tech("custom-pack")
        local colors = r:get_colors_for_research(tech)
        assert.are.equal(0.5, colors[1][1])
        assert.are.equal(0.5, colors[1][2])
        assert.are.equal(0.5, colors[1][3])
      end)

      it("scales all color components by intensity", function ()
        local r = ColorRegistry.new()
        r:set_ingredient_color("custom-pack", { 1.0, 0.0, 0.5 })
        local tech = make_tech("custom-pack")
        local colors = r:get_colors_for_research(tech, 0.5)
        assert.are.equal(1, #colors)
        assert.are.equal(0.5, colors[1][1])
        assert.are.equal(0.0, colors[1][2])
        assert.are.equal(0.25, colors[1][3])
      end)

      it("scales all ingredients independently", function ()
        local r = ColorRegistry.new()
        r:set_ingredient_color("pack-a", { 1.0, 0.0, 0.0 })
        r:set_ingredient_color("pack-b", { 0.0, 1.0, 0.0 })
        local tech = make_tech("pack-a", "pack-b")
        local colors = r:get_colors_for_research(tech, 0.5)
        assert.are.equal(2, #colors)
        assert.are.equal(0.5, colors[1][1])
        assert.are.equal(0.0, colors[2][1])
        assert.are.equal(0.5, colors[2][2])
      end)

      it("scales default colors when no ingredients match", function ()
        local r = ColorRegistry.new()
        local tech = make_tech("unknown-pack")
        local dc = ColorRegistry.default_research_colors[1]
        local colors = r:get_colors_for_research(tech, 0.5)
        assert.are.equal(dc[1] * 0.5, colors[1][1])
        assert.are.equal(dc[2] * 0.5, colors[1][2])
        assert.are.equal(dc[3] * 0.5, colors[1][3])
      end)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("validate_technology_prototypes", function ()
    it("returns nil when all ingredients are registered", function ()
      local r = ColorRegistry.new()
      r:set_ingredient_color("automation-science-pack", { 0.91, 0.16, 0.20 })
      r:set_ingredient_color("logistic-science-pack", { 0.29, 0.97, 0.31 })
      local protos = make_prototypes({
        make_tech("automation-science-pack"),
        make_tech("logistic-science-pack"),
      })
      assert.is_nil(r:validate_technology_prototypes(protos))
    end)

    it("returns sorted list of unregistered ingredient names", function ()
      local r = ColorRegistry.new()
      r:set_ingredient_color("automation-science-pack", { 0.91, 0.16, 0.20 })
      local protos = make_prototypes({
        make_tech("unknown-z"),
        make_tech("unknown-a", "automation-science-pack"),
      })
      local names = r:validate_technology_prototypes(protos)
      assert.is_not_nil(names) --- @cast names -nil
      assert.are.equal(2, #names)
      assert.are.equal("unknown-a", names[1])
      assert.are.equal("unknown-z", names[2])
    end)

    it("deduplicates repeated unregistered ingredients", function ()
      local r = ColorRegistry.new()
      local protos = make_prototypes({
        make_tech("missing-pack"),
        make_tech("missing-pack"),
      })
      local names = r:validate_technology_prototypes(protos)
      assert.are.equal(1, #names)
    end)

    it("returns nil for empty technology list", function ()
      local r = ColorRegistry.new()
      local protos = make_prototypes({})
      assert.is_nil(r:validate_technology_prototypes(protos))
    end)
  end)
end)
