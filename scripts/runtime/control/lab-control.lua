local consts = require("scripts.shared.consts")
local RemoteInterface = require("scripts.runtime.remote-interface")
local ColorRegistry = require("scripts.runtime.color-registry")
local TargetLabRegistry = require("scripts.runtime.target-lab-registry")
local LabOverlayRenderer = require("scripts.runtime.lab-overlay-renderer")

--- @class LabControl : event_handler
local LabControl = {}

--- @type LabOverlayRenderer
local renderer

local function setup_event_handlers()
  script.on_event(defines.events.on_tick, renderer:get_tick_function())
  script.on_nth_tick(5, function () renderer:update_player_view() end)
  script.on_nth_tick(30, function () renderer:update_overlay_states() end)
end

--- Rebuild all overlays and refresh event handlers.
--- render_overlays_for_all_labs() resets chunk_map, so setup_event_handlers() must always
--- follow to give the tick function a fresh reference to the new chunk_map data.
local function rebuild_overlays()
  renderer:render_overlays_for_all_labs()
  setup_event_handlers()
end

function LabControl.on_init()
  local ds_storage = storage --[[@as DiscoScienceStorage]]
  ds_storage.color_registry = ColorRegistry.new()
  ds_storage.target_lab_registry = TargetLabRegistry.new()
  RemoteInterface.bind_storage(ds_storage)

  renderer = LabOverlayRenderer.new(ds_storage.color_registry, ds_storage.target_lab_registry)
  rebuild_overlays()

  ds_storage.color_registry:validate_technology_prototypes()
end

function LabControl.on_load()
  local ds_storage = storage --[[@as DiscoScienceStorage]]
  RemoteInterface.bind_storage(ds_storage)

  renderer = LabOverlayRenderer.new(ds_storage.color_registry, ds_storage.target_lab_registry)

  -- on_load cannot modify game state, so defer rendering to the first tick.
  script.on_event(defines.events.on_tick, function ()
    rebuild_overlays() -- overwrites on_tick event handler
  end)
end

function LabControl.on_configuration_changed()
  rebuild_overlays() -- cancels the deferred render registered in on_load

  local ds_storage = storage --[[@as DiscoScienceStorage]]
  ds_storage.color_registry:validate_technology_prototypes()
end

function LabControl.add_remote_interface()
  -- Compatible with original DiscoScience interface
  remote.add_interface("DiscoScience", RemoteInterface.functions)
end

local function renderer_update_player_view()
  if renderer then
    renderer:update_player_view()
  end
end

local LAB_CREATED_EFFECT_ID = consts.LAB_CREATED_EFFECT_ID
local TARGET_TYPE_ENTITY = defines.target_type.entity

LabControl.events = {
  [defines.events.on_player_changed_position] = renderer_update_player_view,
  [defines.events.on_player_changed_surface] = renderer_update_player_view,
  [defines.events.on_player_display_resolution_changed] = renderer_update_player_view,
  [defines.events.on_player_created] = renderer_update_player_view,
  [defines.events.on_player_removed] = renderer_update_player_view,

  [defines.events.on_player_changed_force] = function ()
    -- Rebuild overlays because the force filter in render_overlay_for_lab depends on the
    -- player's force. Labs belonging to the old force must be removed and new ones added.
    rebuild_overlays()
  end,

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
    if renderer and event.effect_id == LAB_CREATED_EFFECT_ID and event.target_entity then
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
}

return LabControl
