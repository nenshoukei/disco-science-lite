local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local LabPrototypeRegistry = require("scripts.prototype.lab-prototype-registry")
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
    LabPrototypeModifier.modified_labs = {}
    LabPrototypeRegistry.reset()
  end)

  -- -------------------------------------------------------------------
  describe("prepareLab", function ()
    it("modifies the lab prototype", function ()
      local lab = make_lab()
      local off = lab.off_animation
      DiscoScienceInterface.prepareLab(lab)
      assert.are.equal(off, lab.on_animation)
    end)

    it("registers the lab name in LabPrototypeRegistry", function ()
      local lab = make_lab("my-lab")
      DiscoScienceInterface.prepareLab(lab)
      assert.is_not_nil(LabPrototypeRegistry.registered_labs["my-lab"])
    end)

    it("stores animation setting in the registry", function ()
      local lab = make_lab("my-lab")
      DiscoScienceInterface.prepareLab(lab, { animation = "my-anim" })
      local settings = LabPrototypeRegistry.registered_labs["my-lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("my-anim", settings.animation)
    end)

    it("stores scale setting in the registry", function ()
      local lab = make_lab("my-lab")
      DiscoScienceInterface.prepareLab(lab, { scale = 2.5 })
      local settings = LabPrototypeRegistry.registered_labs["my-lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal(2.5, settings.scale)
    end)

    it("registers with empty settings when no settings are passed", function ()
      local lab = make_lab("my-lab")
      DiscoScienceInterface.prepareLab(lab)
      local settings = LabPrototypeRegistry.registered_labs["my-lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.is_nil(settings.animation)
      assert.is_nil(settings.scale)
    end)

    it("registers with empty settings when empty table is passed", function ()
      local lab = make_lab("my-lab")
      DiscoScienceInterface.prepareLab(lab, {})
      local settings = LabPrototypeRegistry.registered_labs["my-lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.is_nil(settings.animation)
      assert.is_nil(settings.scale)
    end)

    it("can prepare multiple labs independently", function ()
      local lab_a = make_lab("lab-a")
      local lab_b = make_lab("lab-b")
      DiscoScienceInterface.prepareLab(lab_a, { animation = "anim-a" })
      DiscoScienceInterface.prepareLab(lab_b, { animation = "anim-b" })
      assert.are.equal("anim-a", LabPrototypeRegistry.registered_labs["lab-a"].animation)
      assert.are.equal("anim-b", LabPrototypeRegistry.registered_labs["lab-b"].animation)
    end)

    -- -------------------------------------------------------------------
    describe("validation", function ()
      it("errors when lab is not a table", function ()
        assert.has_error(function ()
          --- @diagnostic disable-next-line: param-type-mismatch
          DiscoScienceInterface.prepareLab("not-a-table")
        end)
      end)

      it("errors when lab.type is not 'lab'", function ()
        local lab = make_lab()
        lab.type = "item" --[[@as any]]
        assert.has_error(function ()
          DiscoScienceInterface.prepareLab(lab)
        end)
      end)

      it("errors when lab.name is missing", function ()
        local lab = make_lab()
        lab.name = nil --[[@as any]]
        assert.has_error(function ()
          DiscoScienceInterface.prepareLab(lab)
        end)
      end)

      it("errors when lab.name is an empty string", function ()
        local lab = make_lab()
        lab.name = "" --[[@as any]]
        assert.has_error(function ()
          DiscoScienceInterface.prepareLab(lab)
        end)
      end)

      it("errors when settings is not a table", function ()
        local lab = make_lab()
        assert.has_error(function ()
          --- @diagnostic disable-next-line: param-type-mismatch
          DiscoScienceInterface.prepareLab(lab, "not-a-table")
        end)
      end)

      it("errors when settings.animation is an empty string", function ()
        local lab = make_lab()
        assert.has_error(function ()
          --- @diagnostic disable-next-line: param-type-mismatch
          DiscoScienceInterface.prepareLab(lab, { animation = "" })
        end)
      end)

      it("errors when settings.animation is not a string", function ()
        local lab = make_lab()
        assert.has_error(function ()
          --- @diagnostic disable-next-line: assign-type-mismatch
          DiscoScienceInterface.prepareLab(lab, { animation = 123 })
        end)
      end)

      it("errors when settings.scale is zero", function ()
        local lab = make_lab()
        assert.has_error(function ()
          DiscoScienceInterface.prepareLab(lab, { scale = 0 })
        end)
      end)

      it("errors when settings.scale is negative", function ()
        local lab = make_lab()
        assert.has_error(function ()
          DiscoScienceInterface.prepareLab(lab, { scale = -1 })
        end)
      end)

      it("errors when settings.scale is not a number", function ()
        local lab = make_lab()
        assert.has_error(function ()
          --- @diagnostic disable-next-line: assign-type-mismatch
          DiscoScienceInterface.prepareLab(lab, { scale = "big" })
        end)
      end)

      it("accepts nil settings.animation", function ()
        local lab = make_lab()
        assert.no_error(function ()
          DiscoScienceInterface.prepareLab(lab, { animation = nil })
        end)
      end)

      it("accepts nil settings.scale", function ()
        local lab = make_lab()
        assert.no_error(function ()
          DiscoScienceInterface.prepareLab(lab, { scale = nil })
        end)
      end)

      it("accepts a positive scale", function ()
        local lab = make_lab()
        assert.no_error(function ()
          DiscoScienceInterface.prepareLab(lab, { scale = 0.5 })
        end)
      end)
    end)
  end)
end)
