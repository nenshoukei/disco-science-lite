local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
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
    it("registers lab with provided options", function ()
      local lab = make_lab("my-lab")
      DiscoScienceInterface.prepareLab(lab, { animation = "my-anim" })

      local registration = PrototypeLabRegistry.registered_labs["my-lab"]
      assert.is_not_nil(registration) --- @cast registration -nil
      assert.are.equal("my-anim", registration.animation)
    end)

    it("registers with empty options when omitted", function ()
      local lab = make_lab("my-lab")
      DiscoScienceInterface.prepareLab(lab)
      local registration = PrototypeLabRegistry.registered_labs["my-lab"]
      assert.is_not_nil(registration) --- @cast registration -nil
      assert.is_nil(registration.animation)
      assert.is_nil(registration.scale)
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

      it("errors for invalid options", function ()
        local lab = make_lab()
        --- @diagnostic disable-next-line: param-type-mismatch
        assert.has_error(function () DiscoScienceInterface.prepareLab(lab, ("not-a-table")) end)
        assert.has_error(function () DiscoScienceInterface.prepareLab(lab, { animation = "" }) end)
      end)

      it("accepts valid options", function ()
        local lab = make_lab()
        assert.no_error(function () DiscoScienceInterface.prepareLab(lab, { animation = nil }) end)
        assert.no_error(function () DiscoScienceInterface.prepareLab(lab, { animation = "my-anim" }) end)
      end)
    end)
  end)
end)
