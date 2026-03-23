local AnimationHelpers = require("scripts.prototype.animation-helpers")

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

describe("Helpers", function ()
  -- -------------------------------------------------------------------
  describe("remove_layer", function ()
    it("does nothing when layers is nil", function ()
      local animation = {} --[[@as data.Animation]]
      assert.no_error(function () AnimationHelpers.remove_layer(animation, "light.png") end)
    end)

    it("removes a layer matching filename", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
        { filename = "light.png" },
      })
      local light_layer = animation.layers[2]
      local returned = AnimationHelpers.remove_layer(animation, "light.png")
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
      local returned = AnimationHelpers.remove_layer(animation, "light.png")
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
      local returned = AnimationHelpers.remove_layer(animation, "light.png")
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
      local returned = AnimationHelpers.remove_layer(animation, "light.png")
      assert.are.equal(1, #animation.layers)
      assert.are.equal("on.png", animation.layers[1].filename)
      assert.are.equal(light_layer, returned)
    end)

    it("does not remove layers when filename does not match", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
        { filename = "other.png" },
      })
      local returned = AnimationHelpers.remove_layer(animation, "light.png")
      assert.are.equal(2, #animation.layers)
      assert.is_nil(returned)
    end)

    it("does not remove layers when no filenames entry matches", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
        { filenames = { "other.png", "other2.png" } },
      })
      local returned = AnimationHelpers.remove_layer(animation, "light.png")
      assert.are.equal(2, #animation.layers)
      assert.is_nil(returned)
    end)

    it("does not remove layers when no stripes entry matches", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
        { stripes = make_stripes({ "other.png", "other2.png" }) },
      })
      local returned = AnimationHelpers.remove_layer(animation, "light.png")
      assert.are.equal(2, #animation.layers)
      assert.is_nil(returned)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("replace_filename", function ()
    it("replaces top-level filename", function ()
      local animation = ({ filename = "on.png" }) --[[@as data.Animation]]
      AnimationHelpers.replace_filename(animation, "on.png", "on-masked.png")
      assert.are.equal("on-masked.png", animation.filename)
    end)

    it("does not change top-level filename when no match", function ()
      local animation = ({ filename = "on.png" }) --[[@as data.Animation]]
      AnimationHelpers.replace_filename(animation, "other.png", "other-masked.png")
      assert.are.equal("on.png", animation.filename)
    end)

    it("replaces in top-level filenames array", function ()
      local animation = ({ filenames = { "a.png", "b.png" } }) --[[@as data.Animation]]
      AnimationHelpers.replace_filename(animation, "a.png", "a-masked.png")
      assert.are.equal("a-masked.png", animation.filenames[1])
      assert.are.equal("b.png", animation.filenames[2])
    end)

    it("replaces filename in layers", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png" },
        { filename = "other.png" },
      })
      AnimationHelpers.replace_filename(animation, "on.png", "on-masked.png")
      assert.are.equal("on-masked.png", animation.layers[1].filename)
      assert.are.equal("other.png", animation.layers[2].filename)
    end)

    it("replaces filename in layer filenames array", function ()
      local animation = make_animation_with_layers({
        { filenames = { "a.png", "b.png" } },
      })
      AnimationHelpers.replace_filename(animation, "a.png", "a-masked.png")
      assert.are.equal("a-masked.png", animation.layers[1].filenames[1])
      assert.are.equal("b.png", animation.layers[1].filenames[2])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("insert_mask_layer", function ()
    it("does nothing when layers is nil", function ()
      local animation = {} --[[@as data.Animation]]
      assert.no_error(function ()
        AnimationHelpers.insert_mask_layer(animation, "on.png", "mask.png")
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
      AnimationHelpers.insert_mask_layer(animation, "on.png", "mask.png")
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
      AnimationHelpers.insert_mask_layer(animation, "on.png", "mask.png", {
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
      AnimationHelpers.insert_mask_layer(animation, "other.png", "mask.png")
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
      AnimationHelpers.insert_mask_layer(animation, { "a.png", "b.png" }, { "mask-a.png", "mask-b.png" })
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
      AnimationHelpers.insert_mask_layer(animation, { "a.png", "b.png" }, { "mask-a.png", "mask-b.png" })
      assert.are.equal(1, #animation.layers)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("freeze_animation", function ()
    it("does nothing when layers is nil", function ()
      local animation = {} --[[@as data.Animation]]
      assert.no_error(function () AnimationHelpers.freeze_animation(animation) end)
    end)

    it("freezes all layers", function ()
      local animation = make_animation_with_layers({
        { filename = "on.png",     frame_count = 33 },
        { filename = "other.png",  frame_count = 33 },
        { filename = "static.png", frame_count = 1, repeat_count = 33 },
      })
      AnimationHelpers.freeze_animation(animation)
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
      AnimationHelpers.freeze_animation(animation, 3)
      assert.are.same({ 3 }, animation.layers[1].frame_sequence)
      assert.are.same({ 3 }, animation.layers[2].frame_sequence)
    end)
  end)
end)
