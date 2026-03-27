local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")
local Settings = require("scripts.shared.settings")

--- @param created_effect data.Trigger|nil
--- @return data.LabPrototype
local function make_lab(created_effect)
  return ({
    type = "lab",
    name = "test-lab",
    on_animation = { filename = "on.png" },
    off_animation = { filename = "off.png" },
    created_effect = created_effect,
  }) --[[@as data.LabPrototype]]
end

--- @return data.LabPrototype
local function make_lab_with_layers()
  return ({
    type = "lab",
    name = "test-lab",
    on_animation = {
      layers = {
        { filename = "on.png",       frame_count = 8 },
        { filename = "on-light.png", frame_count = 8 },
      },
    },
    off_animation = { filename = "off.png" },
  }) --[[@as data.LabPrototype]]
end

--- Assert that a trigger item is the expected disco-science-lite script trigger.
--- @param trigger any
local function assert_is_dsl_trigger(trigger)
  assert.is_table(trigger)
  assert.are.equal("direct", trigger.type)
  assert.are.equal("instant", trigger.action_delivery.type)
  assert.are.equal("script", trigger.action_delivery.source_effects.type)
  assert.are.equal("ds-create-lab", trigger.action_delivery.source_effects.effect_id)
end

describe("LabPrototypeModifier", function ()
  before_each(function ()
    LabPrototypeModifier.reset()
  end)

  -- -------------------------------------------------------------------
  describe("modify_lab", function ()
    it("does nothing when on_animation is nil", function ()
      local lab = make_lab(nil)
      lab.on_animation = nil --[[@as any]]
      assert.no_error(function () LabPrototypeModifier.modify_lab(lab) end)
    end)

    describe("on_animation freeze", function ()
      before_each(function ()
        PrototypeLabRegistry.reset()
      end)

      it("freezes on_animation layers when registered without animation", function ()
        local lab = make_lab_with_layers()
        _G.data.raw["lab"][lab.name] = lab
        PrototypeLabRegistry.register(lab.name)
        LabPrototypeModifier.modify_lab(lab)
        local layers = lab.on_animation.layers --- @cast layers -nil
        assert.are.same({ 1 }, layers[1].frame_sequence)
        assert.are.same({ 1 }, layers[2].frame_sequence)
        assert.is_nil(layers[1].repeat_count)
        assert.is_nil(layers[2].repeat_count)
      end)

      it("does not freeze when on_animation has no layers", function ()
        local lab = make_lab(nil)
        _G.data.raw["lab"][lab.name] = lab
        PrototypeLabRegistry.register(lab.name)
        assert.no_error(function () LabPrototypeModifier.modify_lab(lab) end)
        assert.are.equal("on.png", lab.on_animation.filename)
      end)

      it("does not freeze when registered with a custom animation", function ()
        local lab = make_lab_with_layers()
        _G.data.raw["lab"][lab.name] = lab
        PrototypeLabRegistry.register(lab.name, { animation = "custom-anim" })
        LabPrototypeModifier.modify_lab(lab)
        local layers = lab.on_animation.layers --- @cast layers -nil
        assert.is_nil(layers[1].frame_sequence)
        assert.is_nil(layers[2].frame_sequence)
      end)

      it("does not freeze when lab is not registered (fallback)", function ()
        local lab = make_lab_with_layers()
        _G.data.raw["lab"][lab.name] = lab
        LabPrototypeModifier.modify_lab(lab)
        local layers = lab.on_animation.layers --- @cast layers -nil
        assert.is_nil(layers[1].frame_sequence)
        assert.is_nil(layers[2].frame_sequence)
      end)
    end)

    it("does nothing when the lab prototype is already modified", function ()
      local lab = make_lab(nil)
      LabPrototypeModifier.modify_lab(lab)
      -- Swap out created_effect to detect a second modification
      lab.created_effect = nil --[[@as any]]
      LabPrototypeModifier.modify_lab(lab)
      assert.is_nil(lab.created_effect)
    end)

    describe("created_effect handling", function ()
      it("sets created_effect directly to the trigger when it was nil", function ()
        local lab = make_lab(nil)
        LabPrototypeModifier.modify_lab(lab)
        assert_is_dsl_trigger(lab.created_effect)
      end)

      it("converts a single TriggerItem to an array and appends the trigger", function ()
        local original_trigger = { type = "direct", action_delivery = { type = "instant" } }
        local lab = make_lab(original_trigger)
        LabPrototypeModifier.modify_lab(lab)
        assert.is_table(lab.created_effect)
        assert.are.equal(2, #lab.created_effect)
        assert.are.equal(original_trigger, lab.created_effect[1])
        assert_is_dsl_trigger(lab.created_effect[2])
      end)

      it("appends the trigger when created_effect is already an array", function ()
        local existing = { type = "direct", action_delivery = { type = "instant" } }
        local lab = make_lab({ existing })
        LabPrototypeModifier.modify_lab(lab)
        assert.are.equal(2, #lab.created_effect)
        assert.are.equal(existing, lab.created_effect[1])
        assert_is_dsl_trigger(lab.created_effect[2])
      end)

      it("does not remove pre-existing triggers in the array", function ()
        local t1 = { type = "direct", action_delivery = { type = "instant" } }
        local t2 = { type = "direct", action_delivery = { type = "instant" } }
        local lab = make_lab({ t1, t2 })
        LabPrototypeModifier.modify_lab(lab)
        assert.are.equal(3, #lab.created_effect)
        assert.are.equal(t1, lab.created_effect[1])
        assert.are.equal(t2, lab.created_effect[2])
        assert_is_dsl_trigger(lab.created_effect[3])
      end)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("modify_registered_labs", function ()
    before_each(function ()
      Settings.is_fallback_enabled = true
      PrototypeLabRegistry.reset()
    end)

    it("modifies registered lab prototype", function ()
      local lab = make_lab(nil)
      PrototypeLabRegistry.register(lab.name)
      LabPrototypeModifier.modify_registered_labs({ [lab.name] = lab })
      assert_is_dsl_trigger(lab.created_effect)
    end)

    it("modifies all registered labs", function ()
      local lab1 = make_lab(nil)
      lab1.name = "test-lab1"
      local lab2 = make_lab(nil)
      lab2.name = "test-lab2"
      PrototypeLabRegistry.register(lab1.name)
      PrototypeLabRegistry.register(lab2.name)
      LabPrototypeModifier.modify_registered_labs({ [lab1.name] = lab1, [lab2.name] = lab2 })
      assert_is_dsl_trigger(lab1.created_effect)
      assert_is_dsl_trigger(lab2.created_effect)
    end)

    it("does nothing when lab_prototypes is empty", function ()
      assert.no_error(function ()
        LabPrototypeModifier.modify_registered_labs({})
      end)
    end)

    it("modifies non-target labs when fallback is enabled", function ()
      local lab = make_lab(nil)
      LabPrototypeModifier.modify_registered_labs({ [lab.name] = lab })
      assert_is_dsl_trigger(lab.created_effect)
    end)

    it("ignores non-target labs when fallback is disabled", function ()
      Settings.is_fallback_enabled = false
      local lab = make_lab(nil)
      LabPrototypeModifier.modify_registered_labs({ [lab.name] = lab })
      assert.are.equal("on.png", lab.on_animation.filename)
      assert.is_nil(lab.created_effect)
    end)

    it("skips excluded labs even when fallback is enabled", function ()
      local lab = make_lab(nil)
      PrototypeLabRegistry.exclude(lab.name)
      LabPrototypeModifier.modify_registered_labs({ [lab.name] = lab })
      assert.is_nil(lab.created_effect)
    end)

    it("skips excluded labs even when explicitly registered", function ()
      local lab = make_lab(nil)
      PrototypeLabRegistry.register(lab.name)
      PrototypeLabRegistry.exclude(lab.name)
      LabPrototypeModifier.modify_registered_labs({ [lab.name] = lab })
      assert.is_nil(lab.created_effect)
    end)
  end)
end)
