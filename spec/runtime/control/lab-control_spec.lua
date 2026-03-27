local reset_mocks = require("spec.helper").reset_mocks
local RemoteInterface = require("scripts.runtime.remote-interface")
local LabControl = require("scripts.runtime.control.lab-control")

--- Build a pre-initialized storage for on_load (mirrors what on_init writes).
--- @return DiscoScienceStorage
local function make_storage()
  return ({
    color_overrides = {},
    lab_scale_overrides = {},
    anim_state = {
      phase = 0,
      phase_speed = 0.025,
      color_function_index = 1,
      saved_tick = 0,
    },
  }) --[[@as DiscoScienceStorage]]
end

--- Build a minimal mock lab entity.
--- @param unit_number number
--- @param surface_index number?
--- @return LuaEntity
local function make_entity(unit_number, surface_index)
  surface_index = surface_index or 1
  return ({
    valid         = true,
    type          = "lab",
    name          = "lab",
    unit_number   = unit_number,
    surface_index = surface_index,
    force_index   = 1,
    position      = { x = 0, y = 0 },
    tile_width    = 3,
    tile_height   = 3,
    prototype     = { tile_width = 3, tile_height = 3 },
    surface       = ({ index = surface_index }) --[[@as LuaSurface]],
    status        = defines.entity_status.working,
  }) --[[@as LuaEntity]]
end

--- Last on_tick handler registered via script.on_event.
--- @type fun()|nil
local captured_tick_handler

--- Common test environment setup shared by both describe blocks.
local function setup_common()
  reset_mocks()

  -- Capture the on_tick handler so tests can fire it manually.
  captured_tick_handler = nil
  _G.script.on_event = function (event_id, handler)
    if event_id == defines.events.on_tick then
      captured_tick_handler = handler
    end
  end

  -- Reset RemoteInterface to unbound state so pending_calls is empty.
  RemoteInterface.bind_registries(nil, nil)
  RemoteInterface.bind_rebuild_callback(nil --[[@as fun()]])
end

describe("LabControl", function ()
  before_each(function ()
    setup_common()
  end)

  -- -------------------------------------------------------------------------
  describe("on_load", function ()
    -- on_load is called during the load stage, where writing to storage causes
    -- a CRC mismatch and desync among players.  All storage access must be
    -- read-only inside on_load itself.
    it("does not write to storage", function ()
      local write_keys = {}
      _G.storage = setmetatable({}, {
        __newindex = function (t, k, v)
          write_keys[#write_keys + 1] = k
          rawset(t, k, v)
        end,
      }) --[[@as DiscoScienceStorage]]

      LabControl.on_load()

      assert.are.equal(
        0, #write_keys,
        "on_load must not write to storage (causes CRC desync); wrote keys: " ..
        table.concat(write_keys, ", ")
      )
    end)

    it("registers an on_tick handler for deferred initialization", function ()
      _G.storage = make_storage()

      LabControl.on_load()

      assert.is_not_nil(captured_tick_handler)
    end)

    -- Remote calls from other mods (e.g. setIngredientColor) that arrive
    -- before on_load is finished must be queued and applied on the first tick,
    -- because storage writes are forbidden during on_load.
    it("defers pending remote calls to the first on_tick", function ()
      _G.storage = make_storage()

      -- Simulate a remote call that arrived before on_load.
      RemoteInterface.functions.setIngredientColor("pending-pack", { 0.5, 0.6, 0.7 })

      LabControl.on_load()

      -- The call must NOT be applied yet: the registry is not bound during on_load.
      assert.is_nil(RemoteInterface.functions.getIngredientColor("pending-pack"))

      -- Fire the first tick handler.
      assert.is_not_nil(captured_tick_handler) --- @cast captured_tick_handler -nil
      captured_tick_handler()

      -- After the first tick, the pending call must be applied.
      local color = RemoteInterface.functions.getIngredientColor("pending-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.5, color.r)
      assert.are.equal(0.6, color.g)
      assert.are.equal(0.7, color.b)
    end)

    it("defers setLabScale pending calls to the first on_tick", function ()
      _G.storage = make_storage()

      -- Simulate a setLabScale call that arrived before on_load.
      RemoteInterface.functions.setLabScale("pending-lab", 3)

      LabControl.on_load()

      -- Before tick: scale_overrides in storage must NOT be written yet.
      -- (lab_registry.scale_overrides is a reference to storage.lab_scale_overrides,
      --  so any set_scale call would be visible here immediately.)
      assert.is_nil(_G.storage.lab_scale_overrides["pending-lab"])

      -- Fire the first tick handler.
      assert.is_not_nil(captured_tick_handler) --- @cast captured_tick_handler -nil
      captured_tick_handler()

      -- After the first tick, the pending setLabScale must be applied to storage.
      assert.are.equal(3, _G.storage.lab_scale_overrides["pending-lab"])
    end)
  end)

  -- -------------------------------------------------------------------------
  describe("on_configuration_changed", function ()
    it("resolves pending remote calls immediately without waiting for a tick", function ()
      _G.storage = make_storage()

      RemoteInterface.functions.setIngredientColor("pending-pack", { 0.5, 0.6, 0.7 })

      LabControl.on_configuration_changed()

      -- The call must already be applied — no tick needed.
      local color = RemoteInterface.functions.getIngredientColor("pending-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.5, color.r)
      assert.are.equal(0.6, color.g)
      assert.are.equal(0.7, color.b)
    end)

    -- When on_load runs before on_configuration_changed (e.g. mod update during a
    -- loaded game), the deferred init tick registered by on_load must be cancelled so
    -- that bind_registries is not called a second time on the first tick.
    it("cancels the deferred on_load tick: pending calls from after on_load are applied immediately", function ()
      _G.storage = make_storage()
      LabControl.on_load()

      -- Queue a pending call *after* on_load (simulates a remote call from another mod).
      RemoteInterface.functions.setIngredientColor("post-load-pack", { 0.1, 0.2, 0.3 })

      LabControl.on_configuration_changed()

      -- Must be applied immediately without firing any tick.
      local color = RemoteInterface.functions.getIngredientColor("post-load-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.1, color.r)
    end)
  end)

  -- -------------------------------------------------------------------------
  describe("on_init", function ()
    -- on_init is allowed to write to storage.  Pending remote calls must be
    -- resolved immediately (no deferred tick required) because bind_registries
    -- is called synchronously during on_init.
    it("resolves pending remote calls immediately without waiting for a tick", function ()
      _G.storage = ({}) --[[@as DiscoScienceStorage]]

      -- Simulate a remote call that arrived before on_init.
      RemoteInterface.functions.setIngredientColor("pending-pack", { 0.5, 0.6, 0.7 })

      LabControl.on_init()

      -- The call must already be applied — no tick needed.
      local color = RemoteInterface.functions.getIngredientColor("pending-pack")
      assert.is_not_nil(color) --- @cast color -nil
      assert.are.equal(0.5, color.r)
      assert.are.equal(0.6, color.g)
      assert.are.equal(0.7, color.b)
    end)

    it("initializes storage with empty override tables", function ()
      local storage = ({}) --[[@as DiscoScienceStorage]]
      _G.storage = storage

      LabControl.on_init()

      assert.is_not_nil(storage.color_overrides)
      assert.is_not_nil(storage.lab_scale_overrides)
      assert.are.equal("table", type(storage.color_overrides))
      assert.are.equal("table", type(storage.lab_scale_overrides))
    end)
  end)
end)

describe("LabControl events", function ()
  before_each(function ()
    setup_common()

    _G.rendering.objects = {}
    _G.rendering.next_id = 1

    _G.storage = ({}) --[[@as DiscoScienceStorage]]
    LabControl.on_init()
  end)

  -- -------------------------------------------------------------------------
  describe("on_script_trigger_effect", function ()
    local handler = LabControl.events[defines.events.on_script_trigger_effect]

    it("renders an overlay when effect_id matches and target_entity is provided", function ()
      local entity = make_entity(42, 1)

      handler(({ effect_id = "ds-create-lab" --[[$LAB_CREATED_EFFECT_ID]], target_entity = entity }) --[[@as EventData.on_script_trigger_effect]])

      assert.are.equal(1, #_G.rendering.get_all_objects("disco-science-lite" --[[$MOD_NAME]]))
    end)

    it("ignores effects with a non-matching effect_id", function ()
      local entity = make_entity(42, 1)

      handler(({ effect_id = "other-effect", target_entity = entity }) --[[@as EventData.on_script_trigger_effect]])

      assert.are.equal(0, #_G.rendering.get_all_objects("disco-science-lite" --[[$MOD_NAME]]))
    end)

    it("ignores effects with no target_entity", function ()
      handler(({ effect_id = "ds-create-lab" --[[$LAB_CREATED_EFFECT_ID]], target_entity = nil }) --[[@as EventData.on_script_trigger_effect]])

      assert.are.equal(0, #_G.rendering.get_all_objects("disco-science-lite" --[[$MOD_NAME]]))
    end)
  end)

  -- -------------------------------------------------------------------------
  describe("on_object_destroyed", function ()
    local handler = LabControl.events[defines.events.on_object_destroyed]

    it("removes the overlay for a destroyed lab entity", function ()
      local entity = make_entity(42, 1)
      LabControl.events[defines.events.on_script_trigger_effect](
        ({ effect_id = "ds-create-lab" --[[$LAB_CREATED_EFFECT_ID]], target_entity = entity }) --[[@as EventData.on_script_trigger_effect]]
      )
      assert.are.equal(1, #_G.rendering.get_all_objects("disco-science-lite" --[[$MOD_NAME]]))

      handler(({ type = defines.target_type.entity, useful_id = 42 }) --[[@as EventData.on_object_destroyed]])

      assert.are.equal(0, #_G.rendering.get_all_objects("disco-science-lite" --[[$MOD_NAME]]))
    end)

    it("does not remove overlays for non-entity destroyed objects", function ()
      local entity = make_entity(42, 1)
      LabControl.events[defines.events.on_script_trigger_effect](
        ({ effect_id = "ds-create-lab" --[[$LAB_CREATED_EFFECT_ID]], target_entity = entity }) --[[@as EventData.on_script_trigger_effect]]
      )

      -- type != defines.target_type.entity, so the overlay must not be removed.
      handler(({ type = 2 --[[@as defines.target_type]], useful_id = 42 }) --[[@as EventData.on_object_destroyed]])

      assert.are.equal(1, #_G.rendering.get_all_objects("disco-science-lite" --[[$MOD_NAME]]))
    end)
  end)

  -- -------------------------------------------------------------------------
  describe("on_surface_cleared and on_surface_deleted", function ()
    it("removes all overlays on the cleared surface", function ()
      LabControl.events[defines.events.on_script_trigger_effect](
        ({ effect_id = "ds-create-lab" --[[$LAB_CREATED_EFFECT_ID]], target_entity = make_entity(10, 1) }) --[[@as EventData.on_script_trigger_effect]]
      )
      LabControl.events[defines.events.on_script_trigger_effect](
        ({ effect_id = "ds-create-lab" --[[$LAB_CREATED_EFFECT_ID]], target_entity = make_entity(11, 1) }) --[[@as EventData.on_script_trigger_effect]]
      )
      assert.are.equal(2, #_G.rendering.get_all_objects("disco-science-lite" --[[$MOD_NAME]]))

      LabControl.events[defines.events.on_surface_cleared](({ surface_index = 1 }) --[[@as EventData.on_surface_cleared]])

      assert.are.equal(0, #_G.rendering.get_all_objects("disco-science-lite" --[[$MOD_NAME]]))
    end)

    it("does not remove overlays on other surfaces", function ()
      LabControl.events[defines.events.on_script_trigger_effect](
        ({ effect_id = "ds-create-lab" --[[$LAB_CREATED_EFFECT_ID]], target_entity = make_entity(10, 1) }) --[[@as EventData.on_script_trigger_effect]]
      )
      LabControl.events[defines.events.on_script_trigger_effect](
        ({ effect_id = "ds-create-lab" --[[$LAB_CREATED_EFFECT_ID]], target_entity = make_entity(20, 2) }) --[[@as EventData.on_script_trigger_effect]]
      )

      LabControl.events[defines.events.on_surface_cleared](({ surface_index = 2 }) --[[@as EventData.on_surface_cleared]])

      -- Only the overlay on surface 2 should be removed.
      assert.are.equal(1, #_G.rendering.get_all_objects("disco-science-lite" --[[$MOD_NAME]]))
    end)

    it("on_surface_deleted uses the same handler as on_surface_cleared", function ()
      assert.are.equal(
        LabControl.events[defines.events.on_surface_cleared],
        LabControl.events[defines.events.on_surface_deleted]
      )
    end)
  end)

  -- -------------------------------------------------------------------------
  describe("script_raised_teleported", function ()
    it("keeps the overlay alive after the lab is teleported on the same surface", function ()
      local entity = make_entity(42, 1)
      LabControl.events[defines.events.on_script_trigger_effect](
        ({ effect_id = "ds-create-lab" --[[$LAB_CREATED_EFFECT_ID]], target_entity = entity }) --[[@as EventData.on_script_trigger_effect]]
      )

      -- Teleport to a new position on the same surface.
      entity.position = { x = 10, y = 10 }
      LabControl.events[defines.events.script_raised_teleported](({ entity = entity }) --[[@as EventData.script_raised_teleported]])

      -- Overlay must still exist.
      assert.are.equal(1, #_G.rendering.get_all_objects("disco-science-lite" --[[$MOD_NAME]]))
    end)
  end)

  -- -------------------------------------------------------------------------
  describe("on_runtime_mod_setting_changed", function ()
    local handler = LabControl.events[defines.events.on_runtime_mod_setting_changed]

    it("ignores settings with a non-matching prefix", function ()
      captured_tick_handler = nil

      handler(({ setting = "other-mod-setting" }) --[[@as EventData.on_runtime_mod_setting_changed]])

      -- setup_event_handlers must NOT have been called.
      assert.is_nil(captured_tick_handler)
    end)

    it("re-registers event handlers when color-saturation setting changes", function ()
      captured_tick_handler = nil

      handler(({ setting = "mks-dsl-color-saturation" --[[$COLOR_SATURATION_NAME]] }) --[[@as EventData.on_runtime_mod_setting_changed]])

      assert.is_not_nil(captured_tick_handler)
    end)

    it("re-registers event handlers when color-brightness setting changes", function ()
      captured_tick_handler = nil

      handler(({ setting = "mks-dsl-color-brightness" --[[$COLOR_BRIGHTNESS_NAME]] }) --[[@as EventData.on_runtime_mod_setting_changed]])

      assert.is_not_nil(captured_tick_handler)
    end)

    it("force re-renders all overlays when lab-blinking-disabled setting changes", function ()
      LabControl.events[defines.events.on_script_trigger_effect](
        ({ effect_id = "ds-create-lab" --[[$LAB_CREATED_EFFECT_ID]], target_entity = make_entity(42, 1) }) --[[@as EventData.on_script_trigger_effect]]
      )
      assert.are.equal(1, #_G.rendering.get_all_objects("disco-science-lite" --[[$MOD_NAME]]))

      -- Force re-render clears all objects (game.surfaces is empty so nothing is recreated).
      handler(({ setting = "mks-dsl-lab-blinking-disabled" --[[$LAB_BLINKING_DISABLED_NAME]] }) --[[@as EventData.on_runtime_mod_setting_changed]])

      assert.are.equal(0, #_G.rendering.get_all_objects("disco-science-lite" --[[$MOD_NAME]]))
    end)
  end)
end)
