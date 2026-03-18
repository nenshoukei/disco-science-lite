local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

--- @param on_animation data.Animation?
--- @return data.LabPrototype
local function make_lab_proto(on_animation)
  return ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
end

--- @param lab_name string
--- @param lab_proto data.LabPrototype
--- @param animations { [string]: data.Animation }?
--- @return data
local function make_data(lab_name, lab_proto, animations)
  return ({ raw = { lab = { [lab_name] = lab_proto }, animation = animations or {} } }) --[[@as data]]
end

--- @return data.Animation
local function make_general_overlay()
  return ({ width = 128, height = 128, scale = 0.5 }) --[[@as data.Animation]]
end

describe("PrototypeLabRegistry", function ()
  before_each(function ()
    PrototypeLabRegistry.reset()
    _G.data = nil
  end)

  -- -------------------------------------------------------------------
  describe("registered_labs", function ()
    it("is empty when initialized", function ()
      assert.is_nil(next(PrototypeLabRegistry.registered_labs, nil))
    end)
  end)

  -- -------------------------------------------------------------------
  describe("excluded_labs", function ()
    it("is empty when initialized", function ()
      assert.is_nil(next(PrototypeLabRegistry.excluded_labs, nil))
    end)
  end)

  -- -------------------------------------------------------------------
  describe("exclude", function ()
    it("adds lab to excluded_labs", function ()
      PrototypeLabRegistry.exclude("my-lab")
      assert.is_true(PrototypeLabRegistry.excluded_labs["my-lab"])
    end)

    it("removes lab from registered_labs", function ()
      PrototypeLabRegistry.register("my-lab", { animation = "my-anim" })
      PrototypeLabRegistry.exclude("my-lab")
      assert.is_nil(PrototypeLabRegistry.registered_labs["my-lab"])
    end)

    it("works on an unregistered lab", function ()
      assert.no_error(function ()
        PrototypeLabRegistry.exclude("unknown-lab")
      end)
      assert.is_true(PrototypeLabRegistry.excluded_labs["unknown-lab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("add_overlay_detection", function ()
    it("stores a detection entry", function ()
      PrototypeLabRegistry.add_overlay_detection("my-anim", { "mod/lab.png" })
      local detections = PrototypeLabRegistry.overlay_detections
      assert.are.equal(1, #detections)
      assert.are.equal("my-anim", detections[1][1])
      assert.is_true(detections[1][2]["mod/lab.png"])
    end)

    it("stores multiple detection entries in order", function ()
      PrototypeLabRegistry.add_overlay_detection("anim-a", { "a.png" })
      PrototypeLabRegistry.add_overlay_detection("anim-b", { "b.png" })
      local detections = PrototypeLabRegistry.overlay_detections
      assert.are.equal(2, #detections)
      assert.are.equal("anim-a", detections[1][1])
      assert.are.equal("anim-b", detections[2][1])
    end)

    it("stores multiple filenames for one detection entry", function ()
      PrototypeLabRegistry.add_overlay_detection("my-anim", { "a.png", "b.png", "c.png" })
      local fn_set = PrototypeLabRegistry.overlay_detections[1][2]
      assert.is_true(fn_set["a.png"])
      assert.is_true(fn_set["b.png"])
      assert.is_true(fn_set["c.png"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("register", function ()
    it("registers a new lab with settings", function ()
      PrototypeLabRegistry.register("my-lab", { animation = "my-anim", scale = 2 })
      local settings = PrototypeLabRegistry.registered_labs["my-lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("my-anim", settings.animation)
      assert.are.equal(2, settings.scale)
    end)

    it("registers a new lab with empty settings when nil is passed (no data mock)", function ()
      PrototypeLabRegistry.register("my-lab", nil)
      local settings = PrototypeLabRegistry.registered_labs["my-lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.is_nil(settings.animation)
      assert.is_nil(settings.scale)
    end)

    it("overwrites existing registration", function ()
      PrototypeLabRegistry.register("lab", { animation = "new-anim", scale = 3 })
      local settings = PrototypeLabRegistry.registered_labs["lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("new-anim", settings.animation)
      assert.are.equal(3, settings.scale)
    end)

    it("removes exclusion when called on an excluded lab", function ()
      PrototypeLabRegistry.exclude("my-lab")
      PrototypeLabRegistry.register("my-lab", { animation = "my-anim" })
      assert.is_nil(PrototypeLabRegistry.excluded_labs["my-lab"])
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["my-lab"])
    end)

    it("can register multiple labs independently", function ()
      PrototypeLabRegistry.register("lab-a", { animation = "anim-a", scale = 1 })
      PrototypeLabRegistry.register("lab-b", { animation = "anim-b", scale = 2 })
      assert.are.equal("anim-a", PrototypeLabRegistry.registered_labs["lab-a"].animation)
      assert.are.equal("anim-b", PrototypeLabRegistry.registered_labs["lab-b"].animation)
    end)

    it("does not detect when animation is explicitly set", function ()
      _G.data = make_data("my-lab", make_lab_proto(
        ({ filename = "mod/lab.png", scale = 2.0 }) --[[@as data.Animation]]
      ))
      PrototypeLabRegistry.add_overlay_detection("detected-anim", { "mod/lab.png" })
      PrototypeLabRegistry.register("my-lab", { animation = "explicit-anim" })
      local settings = PrototypeLabRegistry.registered_labs["my-lab"]
      assert.is_not_nil(settings) --- @cast settings -nil
      assert.are.equal("explicit-anim", settings.animation)
    end)

    -- Auto-detection tests with data mock
    describe("auto-detection", function ()
      it("auto-detects animation from on_animation.filename", function ()
        _G.data = make_data("my-lab", make_lab_proto(
          ({ filename = "mod/lab.png", scale = 0.5 }) --[[@as data.Animation]]
        ))
        PrototypeLabRegistry.add_overlay_detection("my-overlay", { "mod/lab.png" })
        PrototypeLabRegistry.register("my-lab")
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings) --- @cast settings -nil
        assert.are.equal("my-overlay", settings.animation)
      end)

      it("auto-calculates scale as layer_scale / 0.5", function ()
        _G.data = make_data("my-lab", make_lab_proto(
          ({ filename = "mod/lab.png", scale = 1.0 }) --[[@as data.Animation]]
        ))
        PrototypeLabRegistry.add_overlay_detection("my-overlay", { "mod/lab.png" })
        PrototypeLabRegistry.register("my-lab")
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings)           --- @cast settings -nil
        assert.are.equal(2.0, settings.scale) -- 1.0 / 0.5
      end)

      it("uses scale=1.0 default when layer has no scale", function ()
        _G.data = make_data("my-lab", make_lab_proto(
          ({ filename = "mod/lab.png" }) --[[@as data.Animation]]
        ))
        PrototypeLabRegistry.add_overlay_detection("my-overlay", { "mod/lab.png" })
        PrototypeLabRegistry.register("my-lab")
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings)           --- @cast settings -nil
        assert.are.equal(2.0, settings.scale) -- 1.0 (default) / 0.5
      end)

      it("detects from nested layers", function ()
        local on_anim = ({
          layers = {
            { filename = "mod/lab-light.png", scale = 0.5 },
            { filename = "mod/lab.png",       scale = 0.5 },
          },
        }) --[[@as data.Animation]]
        _G.data = make_data("my-lab", make_lab_proto(on_anim))
        PrototypeLabRegistry.add_overlay_detection("my-overlay", { "mod/lab.png" })
        PrototypeLabRegistry.register("my-lab")
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings)           --- @cast settings -nil
        assert.are.equal("my-overlay", settings.animation)
        assert.are.equal(1.0, settings.scale) -- 0.5 / 0.5
      end)

      it("detects from filenames array", function ()
        local on_anim = ({
          filenames = { "mod/lab-a.png", "mod/lab-b.png" },
          scale = 0.5,
        }) --[[@as data.Animation]]
        _G.data = make_data("my-lab", make_lab_proto(on_anim))
        PrototypeLabRegistry.add_overlay_detection("my-overlay", { "mod/lab-b.png" })
        PrototypeLabRegistry.register("my-lab")
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings) --- @cast settings -nil
        assert.are.equal("my-overlay", settings.animation)
      end)

      it("preserves explicit scale when animation is auto-detected", function ()
        _G.data = make_data("my-lab", make_lab_proto(
          ({ filename = "mod/lab.png", scale = 1.0 }) --[[@as data.Animation]]
        ))
        PrototypeLabRegistry.add_overlay_detection("my-overlay", { "mod/lab.png" })
        PrototypeLabRegistry.register("my-lab", { scale = 3.0 })
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings)           --- @cast settings -nil
        assert.are.equal("my-overlay", settings.animation)
        assert.are.equal(3.0, settings.scale) -- preserved, not overwritten by 2.0
      end)

      it("returns nil when data is nil (test environment)", function ()
        _G.data = nil
        PrototypeLabRegistry.add_overlay_detection("my-overlay", { "mod/lab.png" })
        PrototypeLabRegistry.register("my-lab")
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings) --- @cast settings -nil
        assert.is_nil(settings.animation)
        assert.is_nil(settings.scale)
      end)

      it("returns nil when lab has no on_animation", function ()
        _G.data = make_data("my-lab", make_lab_proto(nil))
        PrototypeLabRegistry.add_overlay_detection("my-overlay", { "mod/lab.png" })
        PrototypeLabRegistry.register("my-lab")
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings) --- @cast settings -nil
        assert.is_nil(settings.animation)
      end)

      it("returns nil when lab does not exist in data.raw", function ()
        _G.data = ({ raw = { lab = {}, animation = {} } }) --[[@as data]]
        PrototypeLabRegistry.add_overlay_detection("my-overlay", { "mod/lab.png" })
        PrototypeLabRegistry.register("unknown-lab")
        local settings = PrototypeLabRegistry.registered_labs["unknown-lab"]
        assert.is_not_nil(settings) --- @cast settings -nil
        assert.is_nil(settings.animation)
      end)
    end)

    -- General overlay fallback tests
    describe("general overlay fallback", function ()
      it("falls back to general-overlay when no detection matches", function ()
        local on_anim = ({
          filename = "mod/other-lab.png",
          width = 128,
          height = 128,
          scale = 0.5,
        }) --[[@as data.Animation]]
        _G.data = make_data("my-lab", make_lab_proto(on_anim), {
          ["mks-dsl-general-overlay"] = make_general_overlay(),
        })
        PrototypeLabRegistry.add_overlay_detection("my-overlay", { "mod/lab.png" })
        PrototypeLabRegistry.register("my-lab")
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings) --- @cast settings -nil
        assert.are.equal("mks-dsl-general-overlay", settings.animation)
      end)

      it("computes scale as max(w,h)*layer_scale / general_effective", function ()
        -- Lab: 256x256 pixels at scale=0.5 → effective = 128
        -- General overlay: 128x128 at scale=0.5 → effective = 64
        -- Expected overlay scale = 128 / 64 = 2.0
        local on_anim = ({
          filename = "mod/other-lab.png",
          width = 256,
          height = 256,
          scale = 0.5,
        }) --[[@as data.Animation]]
        _G.data = make_data("my-lab", make_lab_proto(on_anim), {
          ["mks-dsl-general-overlay"] = make_general_overlay(),
        })
        PrototypeLabRegistry.register("my-lab")
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings) --- @cast settings -nil
        assert.are.equal(2.0, settings.scale)
      end)

      it("uses max dimension (width vs height) for non-square lab", function ()
        -- Lab: 320x192 pixels at scale=0.5 → max_dim = max(320,192)*0.5 = 160
        -- Expected overlay scale = 160 / 64 = 2.5
        local on_anim = ({
          filename = "mod/other-lab.png",
          width = 320,
          height = 192,
          scale = 0.5,
        }) --[[@as data.Animation]]
        _G.data = make_data("my-lab", make_lab_proto(on_anim), {
          ["mks-dsl-general-overlay"] = make_general_overlay(),
        })
        PrototypeLabRegistry.register("my-lab")
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings) --- @cast settings -nil
        assert.are.equal(2.5, settings.scale)
      end)

      it("returns nil when on_animation has no width/height", function ()
        local on_anim = ({
          filename = "mod/other-lab.png",
          scale = 0.5,
        }) --[[@as data.Animation]]
        _G.data = make_data("my-lab", make_lab_proto(on_anim), {
          ["mks-dsl-general-overlay"] = make_general_overlay(),
        })
        PrototypeLabRegistry.register("my-lab")
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings) --- @cast settings -nil
        assert.is_nil(settings.animation)
        assert.is_nil(settings.scale)
      end)

      it("returns nil when general-overlay is not in data.raw.animation", function ()
        local on_anim = ({
          filename = "mod/other-lab.png",
          width = 128,
          height = 128,
          scale = 0.5,
        }) --[[@as data.Animation]]
        _G.data = make_data("my-lab", make_lab_proto(on_anim)) -- no animations mock
        PrototypeLabRegistry.register("my-lab")
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings) --- @cast settings -nil
        assert.is_nil(settings.animation)
      end)

      it("prefers registered detection over general-overlay fallback", function ()
        local on_anim = ({
          filename = "mod/lab.png",
          width = 128,
          height = 128,
          scale = 0.5,
        }) --[[@as data.Animation]]
        _G.data = make_data("my-lab", make_lab_proto(on_anim), {
          ["mks-dsl-general-overlay"] = make_general_overlay(),
        })
        PrototypeLabRegistry.add_overlay_detection("my-specific-overlay", { "mod/lab.png" })
        PrototypeLabRegistry.register("my-lab")
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings) --- @cast settings -nil
        assert.are.equal("my-specific-overlay", settings.animation)
      end)

      it("uses size (scalar) when width/height are absent", function ()
        -- Lab: size=256 (both w/h) at scale=0.5 → bbox 128x128
        -- Expected scale = 128 / 64 = 2.0
        local on_anim = ({
          filename = "mod/other-lab.png",
          size = 256,
          scale = 0.5,
        }) --[[@as data.Animation]]
        _G.data = make_data("my-lab", make_lab_proto(on_anim), {
          ["mks-dsl-general-overlay"] = make_general_overlay(),
        })
        PrototypeLabRegistry.register("my-lab")
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings) --- @cast settings -nil
        assert.are.equal(2.0, settings.scale)
      end)

      it("uses size (tuple) when width/height are absent", function ()
        -- Lab: size={320,192} at scale=0.5 → bbox 160x96
        -- Expected scale = 160 / 64 = 2.5
        local on_anim = ({
          filename = "mod/other-lab.png",
          size = { 320, 192 },
          scale = 0.5,
        }) --[[@as data.Animation]]
        _G.data = make_data("my-lab", make_lab_proto(on_anim), {
          ["mks-dsl-general-overlay"] = make_general_overlay(),
        })
        PrototypeLabRegistry.register("my-lab")
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings) --- @cast settings -nil
        assert.are.equal(2.5, settings.scale)
      end)

      it("accounts for shift when computing bounding box", function ()
        -- Two 64x64 sprites at scale=0.5 shifted left/right by 2 tiles
        -- Each: hw = 64*0.5/2 = 16px, cx = ±2*32 = ±64px
        -- Combined x extent: -80 to +80 → width=160, y: -16 to +16 → height=32
        -- max_dim = 160, general_eff = max(128,128)*0.5 = 64
        -- Expected scale = 160 / 64 = 2.5
        local on_anim = ({
          layers = {
            { filename = "mod/lab-left.png",  width = 64, height = 64, scale = 0.5, shift = { -2, 0 } },
            { filename = "mod/lab-right.png", width = 64, height = 64, scale = 0.5, shift = { 2, 0 } },
          },
        }) --[[@as data.Animation]]
        _G.data = make_data("my-lab", make_lab_proto(on_anim), {
          ["mks-dsl-general-overlay"] = make_general_overlay(),
        })
        PrototypeLabRegistry.register("my-lab")
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings) --- @cast settings -nil
        assert.are.equal(2.5, settings.scale)
      end)

      it("preserves explicit scale with general-overlay fallback", function ()
        local on_anim = ({
          filename = "mod/other-lab.png",
          width = 256,
          height = 256,
          scale = 0.5,
        }) --[[@as data.Animation]]
        _G.data = make_data("my-lab", make_lab_proto(on_anim), {
          ["mks-dsl-general-overlay"] = make_general_overlay(),
        })
        PrototypeLabRegistry.register("my-lab", { scale = 1.5 })
        local settings = PrototypeLabRegistry.registered_labs["my-lab"]
        assert.is_not_nil(settings)           --- @cast settings -nil
        assert.are.equal("mks-dsl-general-overlay", settings.animation)
        assert.are.equal(1.5, settings.scale) -- preserved
      end)
    end)
  end)

  -- -------------------------------------------------------------------
  describe("reset", function ()
    it("clears registrations", function ()
      PrototypeLabRegistry.register("my-lab", { animation = "my-anim" })
      PrototypeLabRegistry.reset()
      assert.is_nil(next(PrototypeLabRegistry.registered_labs, nil))
    end)

    it("clears excluded_labs", function ()
      PrototypeLabRegistry.exclude("my-lab")
      PrototypeLabRegistry.reset()
      assert.is_nil(next(PrototypeLabRegistry.excluded_labs, nil))
    end)

    it("clears overlay_detections", function ()
      PrototypeLabRegistry.add_overlay_detection("my-anim", { "my-file.png" })
      PrototypeLabRegistry.reset()
      assert.are.equal(0, #PrototypeLabRegistry.overlay_detections)
    end)

    it("returns independent tables after each reset (no shared state)", function ()
      local before_labs = PrototypeLabRegistry.registered_labs
      local before_detections = PrototypeLabRegistry.overlay_detections
      PrototypeLabRegistry.reset()
      assert.are_not.equal(before_labs, PrototypeLabRegistry.registered_labs)
      assert.are_not.equal(before_detections, PrototypeLabRegistry.overlay_detections)
    end)
  end)
end)
