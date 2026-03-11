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

  local tracker_update_function = renderer:get_tracker_update_function()
  script.on_nth_tick(10, tracker_update_function)
  script.on_event({
    defines.events.on_player_changed_position,
    defines.events.on_player_changed_surface,
    defines.events.on_player_changed_force,
    defines.events.on_player_display_resolution_changed,
    defines.events.on_player_created,
  }, tracker_update_function)
  script.on_event({
    defines.events.on_player_removed,
    defines.events.on_player_left_game,
    defines.events.on_player_kicked,
  }, function (event)
    renderer:remove_player_tracker(event.player_index --[[@as integer]])
    tracker_update_function() -- update for force_state player position
  end)

  local state_update_function = renderer:get_state_update_function()
  script.on_nth_tick(30, state_update_function)
  script.on_event({
    defines.events.on_research_started,
    defines.events.on_research_finished,
    defines.events.on_research_cancelled,
  }, state_update_function)
end

--- Rebuild all overlays and refresh event handlers.
local function rebuild_overlays()
  renderer:render_overlays_for_all_labs()
  setup_event_handlers()
end

function LabControl.on_init()
  local ds_storage = storage --[[@as DiscoScienceStorage]]
  ds_storage.color_registry = ColorRegistry.new()
  ds_storage.color_registry:load_prototype_colors(true)
  ds_storage.lab_registry = LabRegistry.new()
  ds_storage.lab_registry:load_prototype_settings(true)
  RemoteInterface.bind_storage(ds_storage)

  renderer = LabOverlayRenderer.new(ds_storage.color_registry, ds_storage.lab_registry)
  rebuild_overlays()
  RemoteInterface.bind_rebuild_callback(rebuild_overlays)

  ds_storage.color_registry:validate_technology_prototypes()
end

function LabControl.on_load()
  local ds_storage = storage --[[@as DiscoScienceStorage]]
  RemoteInterface.bind_storage(ds_storage)

  renderer = LabOverlayRenderer.new(ds_storage.color_registry, ds_storage.lab_registry)

  -- on_load cannot modify game state, so defer rendering to the first tick.
  script.on_event(defines.events.on_tick, function ()
    rebuild_overlays() -- overwrites on_tick event handler
    RemoteInterface.bind_rebuild_callback(rebuild_overlays)
  end)
end

function LabControl.on_configuration_changed()
  local ds_storage = storage --[[@as DiscoScienceStorage]]
  -- Reload prototype settings first in case mods were added/removed.
  -- These do not overwrite any existing values set by remote calls at runtime.
  ds_storage.color_registry:load_prototype_colors(false)
  ds_storage.lab_registry:load_prototype_settings(false)

  rebuild_overlays() -- cancels the deferred render registered in on_load
  RemoteInterface.bind_rebuild_callback(rebuild_overlays)

  ds_storage.color_registry:validate_technology_prototypes()
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
    if renderer and event.effect_id == "ds-create-lab" --[[$LAB_CREATED_EFFECT_ID]] and event.target_entity then
      renderer:render_overlay_for_lab(event.target_entity)
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

  [defines.events.on_runtime_mod_setting_changed] = function ()
    rebuild_overlays()
  end,
}

return LabControl
