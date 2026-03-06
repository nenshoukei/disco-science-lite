local LabPrototypeModifier = require("scripts.prototype.lab-prototype-modifier")

--- @param created_effect data.Trigger|nil
--- @return data.LabPrototype
local function make_lab(created_effect)
  return ({
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
  -- -------------------------------------------------------------------
  describe("modify_lab", function ()
    it("replaces on_animation with off_animation", function ()
      local lab = make_lab(nil)
      local off = lab.off_animation
      LabPrototypeModifier.modify_lab(lab)
      assert.are.equal(off, lab.on_animation)
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
  describe("modify_target_labs", function ()
    it("modifies lab prototype when present", function ()
      local lab = make_lab(nil)
      local off = lab.off_animation
      LabPrototypeModifier.modify_target_labs({ lab = lab })
      assert.are.equal(off, lab.on_animation)
      assert_is_dsl_trigger(lab.created_effect)
    end)

    it("modifies biolab prototype when present", function ()
      local biolab = make_lab(nil)
      local off = biolab.off_animation
      LabPrototypeModifier.modify_target_labs({ biolab = biolab })
      assert.are.equal(off, biolab.on_animation)
      assert_is_dsl_trigger(biolab.created_effect)
    end)

    it("modifies all target labs present", function ()
      local lab = make_lab(nil)
      local biolab = make_lab(nil)
      LabPrototypeModifier.modify_target_labs({ lab = lab, biolab = biolab })
      assert_is_dsl_trigger(lab.created_effect)
      assert_is_dsl_trigger(biolab.created_effect)
    end)

    it("does nothing when lab_prototypes is empty", function ()
      assert.no_error(function ()
        LabPrototypeModifier.modify_target_labs({})
      end)
    end)

    it("ignores non-target labs in lab_prototypes", function ()
      local other = make_lab(nil)
      LabPrototypeModifier.modify_target_labs({ ["other-lab"] = other })
      -- on_animation should remain unchanged
      assert.are.equal("on.png", other.on_animation.filename)
      assert.is_nil(other.created_effect)
    end)
  end)
end)
