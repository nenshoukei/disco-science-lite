local AnimationHelpers = require("scripts.prototype.animation-helpers")
local OnAnimationModifier = AnimationHelpers.OnAnimationModifier

--- @param layers data.Animation[]
--- @return data.Animation
local function make_animation_with_layers(layers)
  return ({ layers = layers }) --[[@as data.Animation]]
end

--- @param filenames string[]
--- @return data.Stripe[]
local function make_stripes(filenames)
  local stripes = {}
  for i, filename in ipairs(filenames) do
    stripes[i] = {
      filename = filename,
      width_in_frames = 1,
      height_in_frames = 1,
    }
  end
  return stripes
end

--- @param animation data.Animation
--- @return OnAnimationModifier
local function make_modifier(animation)
  return OnAnimationModifier.new(animation)
end

describe("AnimationHelpers", function ()
  -- -------------------------------------------------------------------
  describe("copy_geometric_properties", function ()
    it("copies all geometric properties from source", function ()
      --- @type data.Animation
      local source = {
        filename = "on.png",
        size = 200,
        width = 194,
        height = 174,
        x = 10,
        y = 20,
        position = { 5, 5 },
        shift = { 0, 0.05 },
        scale = 0.5,
        run_mode = "forward",
        frame_count = 33,
        line_length = 11,
        animation_speed = 0.3,
        max_advance = 1,
        repeat_count = 5,
        frame_sequence = { 1, 2, 3 },
        -- Non-geometric properties
        blend_mode = "additive",
        draw_as_glow = true,
      } --[[@as data.Animation]]
      local result = AnimationHelpers.copy_geometric_properties(source)
      assert.are.equal(200, result.size)
      assert.are.equal(194, result.width)
      assert.are.equal(174, result.height)
      assert.are.equal(10, result.x)
      assert.are.equal(20, result.y)
      assert.are.same({ 5, 5 }, result.position)
      assert.are.same({ 0, 0.05 }, result.shift)
      assert.are.equal(0.5, result.scale)
      assert.are.equal("forward", result.run_mode)
      assert.are.equal(33, result.frame_count)
      assert.are.equal(11, result.line_length)
      assert.are.equal(0.3, result.animation_speed)
      assert.are.equal(1, result.max_advance)
      assert.are.equal(5, result.repeat_count)
      assert.are.same({ 1, 2, 3 }, result.frame_sequence)
      -- Non-geometric properties are NOT copied
      assert.is_nil(result.blend_mode)
      assert.is_nil(result.draw_as_glow)
      assert.is_nil(result.filename)
    end)

    it("skips properties not present in source", function ()
      local source = ({ width = 100 }) --[[@as data.Animation]]
      local result = AnimationHelpers.copy_geometric_properties(source)
      assert.are.equal(100, result.width)
      assert.is_nil(result.height)
      assert.is_nil(result.scale)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("convert_to_animation_prototype", function ()
    it("converts an animation to an animation prototype", function ()
      local animation = ({ filename = "on.png", width = 100, height = 80 }) --[[@as data.Animation]]
      local result = AnimationHelpers.convert_to_animation_prototype(animation, { name = "my-anim" })
      assert.are.equal("animation", result.type)
      assert.are.equal("my-anim", result.name)
      assert.are.equal("on.png", result.filename)
      assert.are.equal(100, result.width)
      assert.are.equal(80, result.height)
    end)

    it("applies override properties", function ()
      local animation = ({ filename = "on.png", width = 100 }) --[[@as data.Animation]]
      local result = AnimationHelpers.convert_to_animation_prototype(animation, {
        name = "my-anim",
        filename = "override.png",
        blend_mode = "additive",
      })
      assert.are.equal("override.png", result.filename)
      assert.are.equal("additive", result.blend_mode)
    end)

    it("works without override_props", function ()
      local animation = ({ filename = "on.png" }) --[[@as data.Animation]]
      local result = AnimationHelpers.convert_to_animation_prototype(animation)
      assert.are.equal("animation", result.type)
      assert.are.equal("on.png", result.filename)
    end)

    it("does not modify the original animation", function ()
      local animation = ({ filename = "on.png" }) --[[@as data.Animation]]
      AnimationHelpers.convert_to_animation_prototype(animation, { name = "my-anim" })
      assert.is_nil((animation) --[[@as data.AnimationPrototype]].type)
      assert.is_nil((animation) --[[@as data.AnimationPrototype]].name)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("convert_to_animation", function ()
    it("converts an animation prototype to an animation", function ()
      local proto = ({ type = "animation", name = "my-anim", filename = "on.png", width = 100 }) --[[@as data.AnimationPrototype]]
      local result = AnimationHelpers.convert_to_animation(proto)
      assert.is_nil((result) --[[@as any]].type)
      assert.is_nil((result) --[[@as any]].name)
      assert.are.equal("on.png", result.filename)
      assert.are.equal(100, result.width)
    end)

    it("applies override properties", function ()
      local proto = ({ type = "animation", name = "my-anim", filename = "on.png", frame_count = 10 }) --[[@as data.AnimationPrototype]]
      local result = AnimationHelpers.convert_to_animation(proto, {
        frame_sequence = { 1, 2, 3 },
        frame_count = 30,
      })
      assert.are.same({ 1, 2, 3 }, result.frame_sequence)
      assert.are.equal(30, result.frame_count)
      assert.are.equal("on.png", result.filename)
    end)

    it("does not modify the original prototype", function ()
      local proto = ({ type = "animation", name = "my-anim", filename = "on.png" }) --[[@as data.AnimationPrototype]]
      AnimationHelpers.convert_to_animation(proto)
      assert.are.equal("animation", proto.type)
      assert.are.equal("my-anim", proto.name)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("modify_on_animation", function ()
    local saved_data_raw

    before_each(function ()
      saved_data_raw = _G.data and _G.data.raw
      --- @diagnostic disable-next-line: missing-fields
      _G.data = {
        raw = { lab = {} },
      }
    end)

    after_each(function ()
      if saved_data_raw then
        _G.data.raw = saved_data_raw
      else
        _G.data = nil
      end
    end)

    it("calls callback with OnAnimationModifier and lab prototype", function ()
      local on_animation = make_animation_with_layers({
        { filename = "on.png" },
        { filename = "light.png" },
      })
      _G.data.raw.lab["test-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]

      local called = false
      AnimationHelpers.modify_on_animation("test-lab", function (anim, lab)
        called = true
        assert.is_not_nil(lab)
        anim:remove_layer("light.png")
      end)

      assert.is_true(called)
      assert.are.equal(1, #on_animation.layers)
    end)

    it("does not modify the metatable of on_animation", function ()
      local original_mt = {}
      local on_animation = setmetatable(make_animation_with_layers({}), original_mt)
      _G.data.raw.lab["test-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]

      AnimationHelpers.modify_on_animation("test-lab", function () end)

      assert.are.equal(original_mt, getmetatable(on_animation))
    end)

    it("propagates callback errors", function ()
      local on_animation = make_animation_with_layers({})
      _G.data.raw.lab["test-lab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]

      assert.has_error(function ()
        AnimationHelpers.modify_on_animation("test-lab", function ()
          error("test error")
        end)
      end)
    end)

    it("does nothing when lab is not defined", function ()
      local called = false
      assert.no_error(function ()
        AnimationHelpers.modify_on_animation("nonexistent-lab", function ()
          called = true
        end)
      end)
      assert.is_false(called)
    end)

    it("does nothing when lab has no on_animation", function ()
      _G.data.raw.lab["test-lab"] = ({}) --[[@as data.LabPrototype]]
      local called = false
      assert.no_error(function ()
        AnimationHelpers.modify_on_animation("test-lab", function ()
          called = true
        end)
      end)
      assert.is_false(called)
    end)
  end)
end)

describe("OnAnimationModifier", function ()
  -- -------------------------------------------------------------------
  describe("get_layer", function ()
    it("returns nil when layers is nil", function ()
      local modifier = make_modifier({} --[[@as data.Animation]])
      local layer, index = modifier:get_layer("on.png")
      assert.is_nil(layer)
      assert.is_nil(index)
    end)

    it("finds a layer by filename", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
        { filename = "light.png" },
      })
      local modifier = make_modifier(animation)
      local layer, index = modifier:get_layer("light.png")
      assert.are.equal(animation.layers[2], layer)
      assert.are.equal(2, index)
    end)

    it("finds a layer by filenames array entry", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
        { filenames = { "a.png", "b.png" } },
      })
      local modifier = make_modifier(animation)
      local layer, index = modifier:get_layer("b.png")
      assert.are.equal(animation.layers[2], layer)
      assert.are.equal(2, index)
    end)

    it("finds a layer by stripes entry", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
        { stripes = make_stripes({ "stripe-a.png", "stripe-b.png" }) },
      })
      local modifier = make_modifier(animation)
      local layer, index = modifier:get_layer("stripe-b.png")
      assert.are.equal(animation.layers[2], layer)
      assert.are.equal(2, index)
    end)

    it("returns only the first match", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
        { filename = "on.png" },
      })
      local modifier = make_modifier(animation)
      local layer, index = modifier:get_layer("on.png")
      assert.are.equal(animation.layers[1], layer)
      assert.are.equal(1, index)
    end)

    it("returns nil when no match", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
      })
      local modifier = make_modifier(animation)
      local layer, index = modifier:get_layer("nonexistent.png")
      assert.is_nil(layer)
      assert.is_nil(index)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("remove_layer", function ()
    it("does nothing when layers is nil", function ()
      local modifier = make_modifier({} --[[@as data.Animation]])
      assert.no_error(function () modifier:remove_layer("light.png") end)
    end)

    it("removes a layer matching filename", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
        { filename = "light.png" },
      })
      local light_layer = animation.layers[2]
      local modifier = make_modifier(animation)
      local returned = modifier:remove_layer("light.png")
      assert.are.equal(light_layer, returned)
      assert.are.equal(1, #animation.layers)
      assert.are.equal("on.png", animation.layers[1].filename)
    end)

    it("removes only a first layer matching filename", function ()
      local animation = make_animation_with_layers({
        { filename = "light.png" },
        { filename = "light.png" },
      })
      local light_layer1 = animation.layers[1]
      local light_layer2 = animation.layers[2]
      local modifier = make_modifier(animation)
      local returned = modifier:remove_layer("light.png")
      assert.are.equal(light_layer1, returned)
      assert.are.equal(1, #animation.layers)
      assert.are.equal(light_layer2, animation.layers[1])
    end)

    it("removes a layer matching any entry in filenames array", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
        { filenames = { "light.png", "light2.png" } },
      })
      local light_layer = animation.layers[2]
      local modifier = make_modifier(animation)
      local returned = modifier:remove_layer("light.png")
      assert.are.equal(1, #animation.layers)
      assert.are.equal("on.png", animation.layers[1].filename)
      assert.are.equal(light_layer, returned)
    end)

    it("removes a layer matching any entry in stripes array", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
        { stripes = make_stripes({ "light.png", "light2.png" }) },
      })
      local light_layer = animation.layers[2]
      local modifier = make_modifier(animation)
      local returned = modifier:remove_layer("light.png")
      assert.are.equal(1, #animation.layers)
      assert.are.equal("on.png", animation.layers[1].filename)
      assert.are.equal(light_layer, returned)
    end)

    it("does not remove layers when filename does not match", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
        { filename = "other.png" },
      })
      local modifier = make_modifier(animation)
      local returned = modifier:remove_layer("light.png")
      assert.are.equal(2, #animation.layers)
      assert.is_nil(returned)
    end)

    it("does not remove layers when no filenames entry matches", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
        { filenames = { "other.png", "other2.png" } },
      })
      local modifier = make_modifier(animation)
      local returned = modifier:remove_layer("light.png")
      assert.are.equal(2, #animation.layers)
      assert.is_nil(returned)
    end)

    it("does not remove layers when no stripes entry matches", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
        { stripes = make_stripes({ "other.png", "other2.png" }) },
      })
      local modifier = make_modifier(animation)
      local returned = modifier:remove_layer("light.png")
      assert.are.equal(2, #animation.layers)
      assert.is_nil(returned)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("replace_filename", function ()
    it("replaces top-level filename", function ()
      local animation = ({ filename = "on.png" }) --[[@as data.Animation]]
      local modifier = make_modifier(animation)
      modifier:replace_filename("on.png", "on-masked.png")
      assert.are.equal("on-masked.png", animation.filename)
    end)

    it("does not change top-level filename when no match", function ()
      local animation = ({ filename = "on.png" }) --[[@as data.Animation]]
      local modifier = make_modifier(animation)
      modifier:replace_filename("other.png", "other-masked.png")
      assert.are.equal("on.png", animation.filename)
    end)

    it("replaces in top-level filenames array", function ()
      local animation = ({ filenames = { "a.png", "b.png" } }) --[[@as data.Animation]]
      local modifier = make_modifier(animation)
      modifier:replace_filename("a.png", "a-masked.png")
      assert.are.equal("a-masked.png", animation.filenames[1])
      assert.are.equal("b.png", animation.filenames[2])
    end)

    it("replaces filename in layers", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
        { filename = "other.png" },
      })
      local modifier = make_modifier(animation)
      modifier:replace_filename("on.png", "on-masked.png")
      assert.are.equal("on-masked.png", animation.layers[1].filename)
      assert.are.equal("other.png", animation.layers[2].filename)
    end)

    it("replaces filename in layer filenames array", function ()
      local animation = make_animation_with_layers({
        { filenames = { "a.png", "b.png" } },
      })
      local modifier = make_modifier(animation)
      modifier:replace_filename("a.png", "a-masked.png")
      assert.are.equal("a-masked.png", animation.layers[1].filenames[1])
      assert.are.equal("b.png", animation.layers[1].filenames[2])
    end)

    it("replaces filename in top-level stripes", function ()
      local animation = ({ stripes = make_stripes({ "a.png", "b.png" }) }) --[[@as data.Animation]]
      local modifier = make_modifier(animation)
      modifier:replace_filename("a.png", "a-masked.png")
      assert.are.equal("a-masked.png", animation.stripes[1].filename)
      assert.are.equal("b.png", animation.stripes[2].filename)
    end)

    it("replaces filename in layer stripes", function ()
      local animation = make_animation_with_layers({
        { stripes = make_stripes({ "on.png", "other.png" }) },
      })
      local modifier = make_modifier(animation)
      modifier:replace_filename("on.png", "on-masked.png")
      assert.are.equal("on-masked.png", animation.layers[1].stripes[1].filename)
      assert.are.equal("other.png", animation.layers[1].stripes[2].filename)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("insert_mask_layer", function ()
    it("does nothing when layers is nil", function ()
      local modifier = make_modifier({} --[[@as data.Animation]])
      assert.no_error(function ()
        modifier:insert_mask_layer("on.png", "mask.png")
      end)
    end)

    it("inserts a mask layer inheriting geometric properties from the target layer", function ()
      local animation = make_animation_with_layers({
        {
          filename = "on.png",
          width = 194,
          height = 174,
          frame_count = 33,
          line_length = 11,
          scale = 0.5,
          shift = { 0, 0.05 },
          animation_speed = 0.3,
        },
        { filename = "light.png" },
      })
      local modifier = make_modifier(animation)
      modifier:insert_mask_layer("on.png", "mask.png")
      assert.are.equal(3, #animation.layers)
      assert.are.equal("on.png", animation.layers[1].filename)
      local mask = animation.layers[2]
      assert.are.equal("mask.png", mask.filename)
      assert.are.equal(194, mask.width)
      assert.are.equal(174, mask.height)
      assert.are.equal(33, mask.frame_count)
      assert.are.equal(11, mask.line_length)
      assert.are.equal(0.5, mask.scale)
      assert.are.same({ 0, 0.05 }, mask.shift)
      assert.are.equal(0.3, mask.animation_speed)
      assert.are.equal("light.png", animation.layers[3].filename)
    end)

    it("inserts a mask layer with overridden geometric properties", function ()
      local animation = make_animation_with_layers({
        {
          filename = "on.png",
          width = 194,
          height = 174,
          frame_count = 60,
          line_length = 10,
          scale = 0.5,
          shift = { 0, -0.1 },
          animation_speed = 1.0,
        },
      })
      local modifier = make_modifier(animation)
      modifier:insert_mask_layer("on.png", "mask.png", {
        width = 100,
        height = 80,
        shift = { 0, -0.5 },
        line_length = 5,
        animation_speed = 0.85,
      })
      assert.are.equal(2, #animation.layers)
      local mask = animation.layers[2]
      assert.are.equal("mask.png", mask.filename)
      assert.are.equal(100, mask.width)
      assert.are.equal(80, mask.height)
      assert.are.same({ 0, -0.5 }, mask.shift)
      assert.are.equal(5, mask.line_length)
      assert.are.equal(0.85, mask.animation_speed)
      assert.are.equal(60, mask.frame_count) -- inherited
      assert.are.equal(0.5, mask.scale)      -- inherited
    end)

    it("does not insert mask when target filename is not found", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
      })
      local modifier = make_modifier(animation)
      modifier:insert_mask_layer("other.png", "mask.png")
      assert.are.equal(1, #animation.layers)
    end)

    it("inserts mask layer with filenames after layer with matching filenames", function ()
      local animation = make_animation_with_layers({
        {
          filenames = { "a.png", "b.png" },
          width = 200,
          height = 150,
          frame_count = 10,
          line_length = 5,
          lines_per_file = 3,
          scale = 0.5,
          shift = { 0, -0.1 },
          animation_speed = 0.5,
        },
        { filename = "other.png" },
      })
      local modifier = make_modifier(animation)
      modifier:insert_mask_layer({ "a.png", "b.png" }, { "mask-a.png", "mask-b.png" })
      assert.are.equal(3, #animation.layers)
      assert.are.same({ "a.png", "b.png" }, animation.layers[1].filenames)
      local mask = animation.layers[2]
      assert.are.same({ "mask-a.png", "mask-b.png" }, mask.filenames)
      assert.are.equal(200, mask.width)
      assert.are.equal(150, mask.height)
      assert.are.equal(10, mask.frame_count)
      assert.are.equal(5, mask.line_length)
      assert.are.equal(3, mask.lines_per_file)
      assert.are.equal(0.5, mask.scale)
      assert.are.same({ 0, -0.1 }, mask.shift)
      assert.are.equal(0.5, mask.animation_speed)
      assert.are.equal("other.png", animation.layers[3].filename)
    end)

    it("does not insert mask when filenames array does not match target", function ()
      local animation = make_animation_with_layers({
        { filenames = { "a.png", "c.png" } },
      })
      local modifier = make_modifier(animation)
      modifier:insert_mask_layer({ "a.png", "b.png" }, { "mask-a.png", "mask-b.png" })
      assert.are.equal(1, #animation.layers)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("freeze_animation", function ()
    it("does nothing when layers is nil", function ()
      local modifier = make_modifier({} --[[@as data.Animation]])
      assert.no_error(function () modifier:freeze_animation() end)
    end)

    it("freezes all layers", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png",     frame_count = 33 },
        { filename = "other.png",  frame_count = 33 },
        { filename = "static.png", frame_count = 1, repeat_count = 33 },
      })
      local modifier = make_modifier(animation)
      modifier:freeze_animation()
      assert.are.same({ 1 }, animation.layers[1].frame_sequence)
      assert.are.same({ 1 }, animation.layers[2].frame_sequence)
      assert.are.same({ 1 }, animation.layers[3].frame_sequence)
      assert.is_nil(animation.layers[3].repeat_count)
    end)

    it("freezes all layers at specified frame index", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png",    frame_count = 33 },
        { filename = "other.png", frame_count = 33 },
      })
      local modifier = make_modifier(animation)
      modifier:freeze_animation(3)
      assert.are.same({ 3 }, animation.layers[1].frame_sequence)
      assert.are.same({ 3 }, animation.layers[2].frame_sequence)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("apply_lab_modifications", function ()
    local saved_mods

    before_each(function ()
      saved_mods = _G.mods
      _G.mods = {}
    end)

    after_each(function ()
      _G.mods = saved_mods
    end)

    it("removes lab-light layer and freezes animation", function ()
      local animation = make_animation_with_layers({
        { filename = "__base__/graphics/entity/lab/lab.png",        frame_count = 33 },
        { filename = "__base__/graphics/entity/lab/lab-light.png",  frame_count = 33 },
        { filename = "__base__/graphics/entity/lab/lab-shadow.png", frame_count = 33 },
      })
      local modifier = make_modifier(animation)
      modifier:apply_lab_modifications()
      assert.are.equal(2, #animation.layers)
      assert.are.equal("__base__/graphics/entity/lab/lab.png", animation.layers[1].filename)
      assert.are.equal("__base__/graphics/entity/lab/lab-shadow.png", animation.layers[2].filename)
      assert.are.same({ 1 }, animation.layers[1].frame_sequence)
      assert.are.same({ 1 }, animation.layers[2].frame_sequence)
    end)

    it("also removes HD Age lab-light layer when mod is active", function ()
      _G.mods["factorio_hd_age_base_game_production"] = "1.0.0"
      local animation = make_animation_with_layers({
        { filename = "__base__/graphics/entity/lab/lab.png",                                                 frame_count = 33 },
        { filename = "__factorio_hd_age_base_game_production__/data/base/graphics/entity/lab/lab-light.png", frame_count = 33 },
      })
      local modifier = make_modifier(animation)
      modifier:apply_lab_modifications()
      assert.are.equal(1, #animation.layers)
      assert.are.equal("__base__/graphics/entity/lab/lab.png", animation.layers[1].filename)
    end)

    it("does not remove HD Age layer when mod is not active", function ()
      local animation = make_animation_with_layers({
        { filename = "__base__/graphics/entity/lab/lab.png",                                                 frame_count = 33 },
        { filename = "__factorio_hd_age_base_game_production__/data/base/graphics/entity/lab/lab-light.png", frame_count = 33 },
      })
      local modifier = make_modifier(animation)
      modifier:apply_lab_modifications()
      assert.are.equal(2, #animation.layers)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("apply_biolab_modifications", function ()
    local saved_mods

    before_each(function ()
      saved_mods = _G.mods
      _G.mods = {}
    end)

    after_each(function ()
      _G.mods = saved_mods
    end)

    it("removes biolab-lights layer", function ()
      local animation = make_animation_with_layers({
        { filename = "__space-age__/graphics/entity/biolab/biolab.png" },
        { filename = "__space-age__/graphics/entity/biolab/biolab-lights.png" },
        { filename = "__space-age__/graphics/entity/biolab/biolab-shadow.png" },
      })
      local modifier = make_modifier(animation)
      modifier:apply_biolab_modifications()
      assert.are.equal(2, #animation.layers)
      assert.are.equal("__space-age__/graphics/entity/biolab/biolab.png", animation.layers[1].filename)
      assert.are.equal("__space-age__/graphics/entity/biolab/biolab-shadow.png", animation.layers[2].filename)
    end)

    it("also removes HD Age biolab-lights layer when mod is active", function ()
      _G.mods["factorio_hd_age_space_age_production"] = "1.0.0"
      local animation = make_animation_with_layers({
        { filename = "__space-age__/graphics/entity/biolab/biolab.png" },
        { filename = "__factorio_hd_age_space_age_production__/data/space-age/graphics/entity/biolab/biolab-lights.png" },
      })
      local modifier = make_modifier(animation)
      modifier:apply_biolab_modifications()
      assert.are.equal(1, #animation.layers)
    end)

    it("does not remove HD Age layer when mod is not active", function ()
      local animation = make_animation_with_layers({
        { filename = "__space-age__/graphics/entity/biolab/biolab.png" },
        { filename = "__factorio_hd_age_space_age_production__/data/space-age/graphics/entity/biolab/biolab-lights.png" },
      })
      local modifier = make_modifier(animation)
      modifier:apply_biolab_modifications()
      assert.are.equal(2, #animation.layers)
    end)

    it("does not freeze animation", function ()
      local animation = make_animation_with_layers({
        { filename = "__space-age__/graphics/entity/biolab/biolab.png", frame_count = 33 },
      })
      local modifier = make_modifier(animation)
      modifier:apply_biolab_modifications()
      assert.is_nil(animation.layers[1].frame_sequence)
    end)
  end)
end)
