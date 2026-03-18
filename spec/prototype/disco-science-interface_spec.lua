local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local PrototypeColorRegistry = require("scripts.prototype.prototype-color-registry")
local DiscoScienceInterface = require("scripts.prototype.disco-science-interface")

--- @return data.LabPrototype
local function make_lab(name)
  return ({
    type = "lab",
    name = name or "test-lab",
    on_animation = { filename = "on.png" },
    off_animation = { filename = "off.png" },
  }) --[[@as data.LabPrototype]]
end

describe("DiscoScienceInterface", function ()
  before_each(function ()
    PrototypeLabRegistry.reset()
    PrototypeColorRegistry.reset()
  end)

  -- -------------------------------------------------------------------
  describe("excludeLab", function ()
    it("excludes a lab by prototype table", function ()
      local lab = make_lab("my-lab")
      DiscoScienceInterface.excludeLab(lab)
      assert.is_true(PrototypeLabRegistry.excluded_labs["my-lab"])
    end)

    it("excludes a lab by name string", function ()
      DiscoScienceInterface.excludeLab("my-lab")
      assert.is_true(PrototypeLabRegistry.excluded_labs["my-lab"])
    end)

    it("removes existing registration when excluding", function ()
      local lab = make_lab("my-lab")
      DiscoScienceInterface.prepareLab(lab, { animation = "my-anim" })
      DiscoScienceInterface.excludeLab("my-lab")
      assert.is_nil(PrototypeLabRegistry.registered_labs["my-lab"])
    end)

    describe("validation", function ()
      it("errors for invalid arguments", function ()
        --- @diagnostic disable-next-line: param-type-mismatch
        assert.has_error(function () DiscoScienceInterface.excludeLab(123) end)
        assert.has_error(function () DiscoScienceInterface.excludeLab("") end)
        --- @diagnostic disable-next-line: param-type-mismatch
        assert.has_error(function () DiscoScienceInterface.excludeLab({}) end)
      end)

      it("accepts valid arguments", function ()
        assert.no_error(function () DiscoScienceInterface.excludeLab("my-lab") end)
        assert.no_error(function () DiscoScienceInterface.excludeLab(make_lab("my-lab")) end)
      end)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("prepareLab", function ()
    it("registers lab with provided settings", function ()
      local lab = make_lab("my-lab")
      DiscoScienceInterface.prepareLab(lab, { animation = "my-anim" })

      local settings = PrototypeLabRegistry.registered_labs["my-lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("my-anim", settings.animation)
    end)

    it("registers with empty settings when omitted", function ()
      local lab = make_lab("my-lab")
      DiscoScienceInterface.prepareLab(lab)
      local settings = PrototypeLabRegistry.registered_labs["my-lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.is_nil(settings.animation)
      assert.is_nil(settings.scale)
    end)

    it("removes exclusion when called on an excluded lab", function ()
      DiscoScienceInterface.excludeLab("my-lab")
      local lab = make_lab("my-lab")
      DiscoScienceInterface.prepareLab(lab, { animation = "my-anim" })
      assert.is_nil(PrototypeLabRegistry.excluded_labs["my-lab"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["my-lab"])
    end)

    it("can prepare multiple labs independently", function ()
      local lab_a = make_lab("lab-a")
      local lab_b = make_lab("lab-b")
      DiscoScienceInterface.prepareLab(lab_a, { animation = "anim-a" })
      DiscoScienceInterface.prepareLab(lab_b, { animation = "anim-b" })
      assert.are.equal("anim-a", PrototypeLabRegistry.registered_labs["lab-a"].animation)
      assert.are.equal("anim-b", PrototypeLabRegistry.registered_labs["lab-b"].animation)
    end)

    describe("validation", function ()
      it("errors for invalid lab prototype", function ()
        local lab = make_lab()
        --- @diagnostic disable-next-line: param-type-mismatch
        assert.has_error(function () DiscoScienceInterface.prepareLab(("not-a-table")) end)
        assert.has_error(function ()
          lab.type = "item" --[[@as any]]
          DiscoScienceInterface.prepareLab(lab)
        end)
        assert.has_error(function ()
          lab.type = "lab"
          lab.name = ""
          DiscoScienceInterface.prepareLab(lab)
        end)
      end)

      it("errors for invalid settings", function ()
        local lab = make_lab()
        --- @diagnostic disable-next-line: param-type-mismatch
        assert.has_error(function () DiscoScienceInterface.prepareLab(lab, ("not-a-table")) end)
        assert.has_error(function () DiscoScienceInterface.prepareLab(lab, { animation = "" }) end)
      end)

      it("accepts valid optional settings", function ()
        local lab = make_lab()
        assert.no_error(function () DiscoScienceInterface.prepareLab(lab, { animation = nil }) end)
        assert.no_error(function () DiscoScienceInterface.prepareLab(lab, { animation = "my-anim" }) end)
      end)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("setIngredientColor", function ()
    it("stores the color for later retrieval", function ()
      DiscoScienceInterface.setIngredientColor("custom-pack", { 0.1, 0.2, 0.3 })
      local color = PrototypeColorRegistry.get("custom-pack")
      assert.is_not_nil(color)
    end)

    describe("validation", function ()
      it("errors for invalid arguments", function ()
        --- @diagnostic disable-next-line: param-type-mismatch
        assert.has_error(function () DiscoScienceInterface.setIngredientColor(123, { 1, 1, 1 }) end)
        assert.has_error(function () DiscoScienceInterface.setIngredientColor("", { 1, 1, 1 }) end)
        --- @diagnostic disable-next-line: param-type-mismatch
        assert.has_error(function () DiscoScienceInterface.setIngredientColor("p", "red") end)
      end)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("getIngredientColor", function ()
    it("returns color for registered or nil for unregistered", function ()
      DiscoScienceInterface.setIngredientColor("custom-pack", { 0.1, 0.2, 0.3 })
      local color = DiscoScienceInterface.getIngredientColor("custom-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.1, color.r)

      assert.is_nil(DiscoScienceInterface.getIngredientColor("unknown"))
    end)

    describe("validation", function ()
      it("errors for invalid ingredient name", function ()
        --- @diagnostic disable-next-line: param-type-mismatch
        assert.has_error(function () DiscoScienceInterface.getIngredientColor(123) end)
        assert.has_error(function () DiscoScienceInterface.getIngredientColor("") end)
      end)
    end)
  end)
end)
