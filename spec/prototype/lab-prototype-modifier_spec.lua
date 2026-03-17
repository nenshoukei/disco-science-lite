local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

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

    it("applies filename replacement on on_animation.filename", function ()
      LabPrototypeModifier.set_filename_replacement("on.png", "on-masked.png")
      local lab = make_lab(nil)
      LabPrototypeModifier.modify_lab(lab)
      assert.are.equal("on-masked.png", lab.on_animation.filename)
    end)

    it("does not replace on_animation.filename when no replacement is set", function ()
      local lab = make_lab(nil)
      LabPrototypeModifier.modify_lab(lab)
      assert.are.equal("on.png", lab.on_animation.filename)
    end)

    it("applies filename replacement on on_animation.filenames", function ()
      LabPrototypeModifier.set_filename_replacement("a.png", "a-masked.png")
      local lab = make_lab(nil)
      lab.on_animation = { filenames = { "a.png", "b.png" } } --[[@as any]]
      LabPrototypeModifier.modify_lab(lab)
      assert.are.equal("a-masked.png", lab.on_animation.filenames[1])
      assert.are.equal("b.png", lab.on_animation.filenames[2])
    end)

    it("removes layers from on_animation with matching removal filenames", function ()
      LabPrototypeModifier.set_layer_removal("light.png")
      local lab = make_lab(nil)
      lab.on_animation = {
        layers = {
          { filename = "on.png" },
          { filename = "light.png" },
        },
      } --[[@as any]]
      LabPrototypeModifier.modify_lab(lab)
      assert.are.equal(1, #lab.on_animation.layers)
      assert.are.equal("on.png", lab.on_animation.layers[1].filename)
    end)

    it("applies filename replacement on on_animation layer filenames", function ()
      LabPrototypeModifier.set_filename_replacement("on.png", "on-masked.png")
      local lab = make_lab(nil)
      lab.on_animation = {
        layers = {
          { filename = "on.png" },
          { filename = "other.png" },
        },
      } --[[@as any]]
      LabPrototypeModifier.modify_lab(lab)
      assert.are.equal("on-masked.png", lab.on_animation.layers[1].filename)
      assert.are.equal("other.png", lab.on_animation.layers[2].filename)
    end)

    it("does nothing when the lab prototype is already modified", function ()
      local lab = make_lab(nil)
      LabPrototypeModifier.modify_lab(lab)
      lab.on_animation = { filename = "on2.png" }
      LabPrototypeModifier.modify_lab(lab)
      assert.are.equal("on2.png", lab.on_animation.filename)
    end)

    it("inserts a mask layer inheriting geometric properties from the target layer", function ()
      LabPrototypeModifier.set_layer_mask("on.png", "mask.png")
      local lab = make_lab(nil)
      lab.on_animation = {
        layers = {
          {
            filename = "on.png",
            width = 194, height = 174,
            frame_count = 33, line_length = 11,
            scale = 0.5, shift = { 0, 0.05 },
            animation_speed = 0.3,
          },
          { filename = "light.png" },
        },
      } --[[@as any]]
      LabPrototypeModifier.modify_lab(lab)
      assert.are.equal(3, #lab.on_animation.layers)
      assert.are.equal("on.png", lab.on_animation.layers[1].filename)
      local mask = lab.on_animation.layers[2]
      assert.are.equal("mask.png", mask.filename)
      assert.are.equal(194, mask.width)
      assert.are.equal(174, mask.height)
      assert.are.equal(33, mask.frame_count)
      assert.are.equal(11, mask.line_length)
      assert.are.equal(0.5, mask.scale)
      assert.are.same({ 0, 0.05 }, mask.shift)
      assert.are.equal(0.3, mask.animation_speed)
      assert.are.equal("light.png", lab.on_animation.layers[3].filename)
    end)

    it("does not insert mask when target filename is not found", function ()
      LabPrototypeModifier.set_layer_mask("other.png", "mask.png")
      local lab = make_lab(nil)
      lab.on_animation = {
        layers = { { filename = "on.png" } },
      } --[[@as any]]
      LabPrototypeModifier.modify_lab(lab)
      assert.are.equal(1, #lab.on_animation.layers)
    end)

    it("mask insertion happens after removal (removed layers are not targeted)", function ()
      LabPrototypeModifier.set_layer_removal("light.png")
      LabPrototypeModifier.set_layer_mask("light.png", "mask.png")
      local lab = make_lab(nil)
      lab.on_animation = {
        layers = {
          { filename = "on.png" },
          { filename = "light.png" },
        },
      } --[[@as any]]
      LabPrototypeModifier.modify_lab(lab)
      -- light.png removed, mask not inserted (target was removed)
      assert.are.equal(1, #lab.on_animation.layers)
      assert.are.equal("on.png", lab.on_animation.layers[1].filename)
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
      _G.settings.startup[ "mks-dsl-fallback-overlay-enabled" --[[$FALLBACK_OVERLAY_ENABLED_NAME]] ] = { value = true }
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
      _G.settings.startup[ "mks-dsl-fallback-overlay-enabled" --[[$FALLBACK_OVERLAY_ENABLED_NAME]] ].value = false
      local lab = make_lab(nil)
      LabPrototypeModifier.modify_registered_labs({ [lab.name] = lab })
      assert.are.equal("on.png", lab.on_animation.filename)
      assert.is_nil(lab.created_effect)
    end)
  end)
end)
