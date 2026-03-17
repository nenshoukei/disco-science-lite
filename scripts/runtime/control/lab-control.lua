local RemoteInterface = require("scripts.runtime.remote-interface")
local ColorRegistry = require("scripts.runtime.color-registry")
local LabRegistry = require("scripts.runtime.lab-registry")
local LabOverlayRenderer = require("scripts.runtime.lab-overlay-renderer")

--- @class LabControl : event_handler
local LabControl = {}

--- @type LabOverlayRenderer
local renderer

-- Compatible with original DiscoScience interface
remote.add_interface("DiscoScience", RemoteInterface.functions)

local function setup_event_handlers()
  script.on_event(defines.events.on_tick, renderer:get_tick_function())

  local state_update_function = renderer:get_state_update_function()
  script.on_nth_tick(30, state_update_function)
  script.on_event({
    defines.events.on_research_started,
    defines.events.on_research_finished,
    defines.events.on_research_cancelled,
    defines.events.on_player_display_resolution_changed,
  }, state_update_function)
end

--- Rebuild all overlays and refresh event handlers.
local function rebuild_overlays()
  renderer:render_overlays_for_all_labs()
  setup_event_handlers()
end

--- Create fresh registries from prototype data, with stored overrides applied.
---
--- @param ds_storage DiscoScienceStorage
--- @return ColorRegistry, LabRegistry
local function create_registries(ds_storage)
  local color_registry = ColorRegistry.new(ds_storage.color_overrides)
  color_registry:load_prototype_colors()
  local lab_registry = LabRegistry.new(ds_storage.lab_scale_overrides)
  lab_registry:load_prototype_settings()
  return color_registry, lab_registry
end

function LabControl.on_init()
  local ds_storage = storage --[[@as DiscoScienceStorage]]
  ds_storage.color_overrides = {}
  ds_storage.lab_scale_overrides = {}

  local color_registry, lab_registry = create_registries(ds_storage)
  RemoteInterface.bind_registries(color_registry, lab_registry)

  renderer = LabOverlayRenderer.new(color_registry, lab_registry)
  rebuild_overlays()
  RemoteInterface.bind_rebuild_callback(rebuild_overlays)

  color_registry:validate_technology_prototypes()
end

function LabControl.on_load()
  local ds_storage = storage --[[@as DiscoScienceStorage]]

  local color_registry, lab_registry = create_registries(ds_storage)
  renderer = LabOverlayRenderer.new(color_registry, lab_registry)

  -- on_load cannot modify game state, so defer rendering and registry binding to the first tick.
  -- bind_registries flushes pending remote calls (e.g. setLabScale), which write to storage.
  script.on_event(defines.events.on_tick, function ()
    RemoteInterface.bind_registries(color_registry, lab_registry)
    rebuild_overlays() -- overwrites on_tick event handler
    RemoteInterface.bind_rebuild_callback(rebuild_overlays)
  end)
end

function LabControl.on_configuration_changed()
  local ds_storage = storage --[[@as DiscoScienceStorage]]

  local color_registry, lab_registry = create_registries(ds_storage)
  RemoteInterface.bind_registries(color_registry, lab_registry)

  renderer = LabOverlayRenderer.new(color_registry, lab_registry)
  rebuild_overlays() -- cancels the deferred render registered in on_load
  RemoteInterface.bind_rebuild_callback(rebuild_overlays)

  color_registry:validate_technology_prototypes()
end

local TARGET_TYPE_ENTITY = defines.target_type.entity

LabControl.events = {
  --- @param event EventData.on_surface_cleared
  [defines.events.on_surface_cleared] = function (event)
    if renderer then
      renderer:remove_overlays_on_surface(event.surface_index)
    end
  end,

  --- @param event EventData.on_surface_deleted
  [defines.events.on_surface_deleted] = function (event)
    if renderer then
      renderer:remove_overlays_on_surface(event.surface_index)
    end
  end,

  --- @param event EventData.on_script_trigger_effect
  [defines.events.on_script_trigger_effect] = function (event)
    local target_entity = event.target_entity
    if renderer and event.effect_id == "ds-create-lab" --[[$LAB_CREATED_EFFECT_ID]] and target_entity then
      renderer:render_overlay_for_lab(target_entity)
    end
  end,

  --- @param event EventData.on_object_destroyed
  [defines.events.on_object_destroyed] = function (event)
    if renderer and event.type == TARGET_TYPE_ENTITY then
      renderer:remove_overlay_from_lab(event.useful_id)
    end
  end,

  --- @param event EventData.script_raised_teleported
  [defines.events.script_raised_teleported] = function (event)
    if renderer then
      renderer:update_lab_position(event.entity)
    end
  end,

  --- @param event EventData.on_runtime_mod_setting_changed
  [defines.events.on_runtime_mod_setting_changed] = function (event)
    local prefix = "mks-dsl-" --[[$NAME_PREFIX]]
    if string.sub(event.setting, 1, #prefix) == prefix then
      renderer:load_settings()

      if event.setting == "mks-dsl-color-intensity" --[[$COLOR_INTENSITY_NAME]] then
        -- This resets color palette using new color intensity.
        renderer:update_all_forces_current_research()
      elseif event.setting == "mks-dsl-disable-lab-blinking" --[[$DISABLE_LAB_BLINKING_NAME]] then
        -- Force re-render all overlays.
        renderer:render_overlays_for_all_labs(true)
      end

      setup_event_handlers()
    end
  end,
}

commands.add_command(
  "ds-force-render",
  "Force re-render all DiscoScienceLite lab overlays. Just for testing the mod.",
  function (event)
    renderer:render_overlays_for_all_labs(true)
    setup_event_handlers()

    local player = game.get_player(event.player_index)
    if player then player.print("Disco Science Lite: All overlays are re-rendered.", { game_state = false }) end
  end
)

return LabControl
