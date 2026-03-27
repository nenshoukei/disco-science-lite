local RemoteInterface = require("scripts.runtime.remote-interface")
local ColorRegistry = require("scripts.runtime.color-registry")
local LabRegistry = require("scripts.runtime.lab-registry")
local LabOverlayRenderer = require("scripts.runtime.lab-overlay-renderer")
local Settings = require("scripts.shared.settings")

--- @class LabControl : event_handler
local LabControl = {}

--- @type LabOverlayRenderer
local renderer

-- Compatible with original DiscoScience interface
remote.add_interface("DiscoScience", RemoteInterface.functions)

--- @return LabOverlayRenderer
local function create_renderer()
  local ds_storage = storage --[[@as DiscoScienceStorage]]

  local color_registry = ColorRegistry.new(ds_storage.color_overrides)
  color_registry:load_prototype_colors()
  local lab_registry = LabRegistry.new(ds_storage.lab_scale_overrides)
  lab_registry:load_prototype_registrations()

  return LabOverlayRenderer.new(color_registry, lab_registry)
end

local function setup_event_handlers()
  local ds_storage = storage --[[@as DiscoScienceStorage]]
  if not ds_storage.anim_state then
    ds_storage.anim_state = LabOverlayRenderer.create_anim_state()
  end
  script.on_event(defines.events.on_tick, renderer:get_tick_function(ds_storage.anim_state))

  local state_update_function = renderer:get_state_update_function()
  script.on_nth_tick(30, state_update_function)
  script.on_event({
    defines.events.on_research_started,
    defines.events.on_research_finished,
    defines.events.on_research_cancelled,
    defines.events.on_player_display_resolution_changed,
  }, state_update_function)
end

local function validate_technology_prototypes()
  -- Defer the validation for runtime color registration
  script.on_nth_tick(90, function ()
    renderer.color_registry:validate_technology_prototypes()
    script.on_nth_tick(90, nil)
  end)
end

--- Rebuild all overlays and refresh event handlers and registry bindings.
local function rebuild_overlays()
  renderer:render_overlays_for_all_labs()
  setup_event_handlers()
  RemoteInterface.bind_registries(renderer.color_registry, renderer.lab_registry)
  RemoteInterface.bind_rebuild_callback(rebuild_overlays)
end

function LabControl.on_init()
  local ds_storage = storage --[[@as DiscoScienceStorage]]
  ds_storage.color_overrides = {}
  ds_storage.lab_scale_overrides = {}
  ds_storage.anim_state = LabOverlayRenderer.create_anim_state()

  renderer = create_renderer()
  rebuild_overlays()

  validate_technology_prototypes()
end

function LabControl.on_load()
  renderer = create_renderer()

  -- on_load cannot modify game state, so defer rendering and registry binding to the first tick.
  -- bind_registries flushes pending remote calls (e.g. setLabScale), which write to storage.
  script.on_event(defines.events.on_tick, function ()
    rebuild_overlays() -- overwrites on_tick event handler
  end)
end

function LabControl.on_configuration_changed()
  renderer = create_renderer()
  rebuild_overlays() -- cancels the deferred render registered in on_load

  validate_technology_prototypes()
end

local TARGET_TYPE_ENTITY = defines.target_type.entity

LabControl.events = {
  --- @param event EventData.on_surface_cleared|EventData.on_surface_deleted
  [defines.events.on_surface_cleared] = function (event)
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
    if not renderer then return end
    local prefix = "mks-dsl-" --[[$NAME_PREFIX]]
    local setting_name = event.setting
    if string.sub(setting_name, 1, #prefix) == prefix then
      Settings.reload()

      if setting_name == "mks-dsl-color-intensity" --[[$COLOR_INTENSITY_NAME]] then
        -- This resets color palette using new color intensity.
        renderer:update_all_forces_current_research()
      elseif setting_name == "mks-dsl-disable-lab-blinking" --[[$DISABLE_LAB_BLINKING_NAME]] then
        -- Force re-render all overlays.
        renderer:render_overlays_for_all_labs(true)
      end

      setup_event_handlers()
    end
  end,
}

-- Same handler for both surface cleared and deleted events.
LabControl.events[defines.events.on_surface_deleted] = LabControl.events[defines.events.on_surface_cleared]

--- Get the current renderer. Just for testing.
--- @return LabOverlayRenderer
function LabControl.get_renderer()
  return renderer
end

--- Force re-render all lab overlays. Just for testing.
function LabControl.force_render()
  if renderer then
    renderer:render_overlays_for_all_labs(true)
    setup_event_handlers()
  end
end

return LabControl
