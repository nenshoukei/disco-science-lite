local consts = require("scripts.shared.consts")
local RemoteInterface = require("scripts.runtime.remote-interface")
local ColorRegistry = require("scripts.runtime.color-registry")
local LabOverlayRenderer = require("scripts.runtime.lab-overlay-renderer")

--- @class LabControl : event_handler
local LabControl = {}

--- @type LabOverlayRenderer
local renderer

local function setup_event_handlers()
  script.on_nth_tick(2, renderer:get_tick_function())
  script.on_nth_tick(5, function () renderer:update_player_view() end)
end

function LabControl.on_init()
  renderer = LabOverlayRenderer.new(ColorRegistry.new())
  storage.renderer = renderer
  RemoteInterface.bind_storage(storage --[[@as DiscoScienceStorage]])
  renderer:render_overlays_for_all_labs()
  setup_event_handlers()

  -- Other mods that register ingredient colors via RemoteInterface at the top level of
  -- their control.lua are guaranteed to have registered by this point. However, mods that
  -- register inside their own on_init handler may not have run yet, depending on load order.
  renderer.color_registry:validate_technology_prototypes()
end

function LabControl.on_load()
  renderer = storage.renderer
  RemoteInterface.bind_storage(storage --[[@as DiscoScienceStorage]])
  setup_event_handlers()
end

function LabControl.on_configuration_changed()
  renderer:render_overlays_for_all_labs()

  -- on_configuration_changed fires after all mods' on_init/on_load, so all ingredient
  -- color registrations are guaranteed to be complete at this point.
  renderer.color_registry:validate_technology_prototypes()
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
  [defines.events.on_player_changed_force] = renderer_update_player_view,
  [defines.events.on_player_changed_position] = renderer_update_player_view,
  [defines.events.on_player_changed_surface] = renderer_update_player_view,
  [defines.events.on_player_display_resolution_changed] = renderer_update_player_view,
  [defines.events.on_player_created] = renderer_update_player_view,
  [defines.events.on_player_removed] = renderer_update_player_view,

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
