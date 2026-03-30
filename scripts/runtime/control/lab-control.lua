local RemoteInterface = require("scripts.runtime.remote-interface")
local ColorRegistry = require("scripts.runtime.color-registry")
local LabRegistry = require("scripts.runtime.lab-registry")
local LabOverlayRenderer = require("scripts.runtime.lab-overlay-renderer")
local Settings = require("scripts.shared.settings")

--- @class LabControl : event_handler
local LabControl = {}

--- @type LabOverlayRenderer
local renderer

local TARGET_TYPE_ENTITY = defines.target_type.entity
local TARGET_TYPE_RENDER_OBJECT = defines.target_type.render_object

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
  local tick_function, request_state_update, update_zoom_reach = renderer:get_tick_function(ds_storage.anim_state)
  script.on_event(defines.events.on_tick, tick_function)
  script.on_nth_tick(180, update_zoom_reach)

  script.on_event({
    defines.events.on_research_started,
    defines.events.on_research_finished,
    defines.events.on_research_cancelled,
  }, request_state_update)

  script.on_event({
    defines.events.on_player_created,
    defines.events.on_singleplayer_init,
    defines.events.on_player_joined_game,
    defines.events.on_player_changed_force,
    defines.events.on_multiplayer_init,
    defines.events.on_force_created,
    defines.events.on_forces_merged,
  }, setup_event_handlers)

  -- When a player leaves, hide all overlays first so labs from their viewport
  -- don't remain colorized. Same for a player's viewport being small.
  -- The new tick function will re-show labs in the remaining players' viewports on the next tick.
  script.on_event({
    defines.events.on_player_left_game,
    defines.events.on_player_display_resolution_changed,
  }, function ()
    renderer:hide_all_overlays()
    setup_event_handlers()
  end)

  script.on_event(defines.events.on_script_trigger_effect, function (event)
    local target_entity = event.target_entity
    if event.effect_id == "ds-create-lab" --[[$LAB_CREATED_EFFECT_ID]] and target_entity then
      renderer:render_overlay_for_lab(target_entity)
    end
  end)

  script.on_event(defines.events.on_object_destroyed, function (event)
    if event.type == TARGET_TYPE_ENTITY then
      renderer:remove_overlay_from_lab(event.useful_id)
      request_state_update()
    elseif event.type == TARGET_TYPE_RENDER_OBJECT then
      renderer:on_render_object_destroyed(event.useful_id)
      request_state_update()
    end
  end)

  script.on_event({
    defines.events.on_surface_cleared,
    defines.events.on_surface_deleted,
  }, function (event)
    --- @cast event EventData.on_surface_cleared|EventData.on_surface_deleted
    renderer:remove_overlays_on_surface(event.surface_index)
    request_state_update()
  end)

  script.on_event(defines.events.script_raised_teleported, function (event)
    renderer:update_lab_position(event.entity)
    request_state_update()
  end)

  script.on_event(defines.events.on_runtime_mod_setting_changed, function (event)
    local prefix = "mks-dsl-" --[[$NAME_PREFIX]]
    local setting_name = event.setting
    if string.sub(setting_name, 1, #prefix) == prefix then
      Settings.reload()

      if setting_name == "mks-dsl-lab-blinking-disabled" --[[$LAB_BLINKING_DISABLED_NAME]] then
        -- Force re-render all overlays.
        renderer:render_overlays_for_all_labs(true)
      end

      setup_event_handlers()
    end
  end)
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
  -- on_load cannot modify game state or access game API, so:
  -- 1. Rendering is deferred to the first tick (rendering modifies game state).
  -- 2. setup_event_handlers() cannot be called here because get_tick_function() needs game access.
  --
  -- However, Factorio requires that on_load registers the EXACT same set of events as the server.
  -- Register all events with noop handlers here; rebuild_overlays() on the first tick installs real ones.
  script.on_event(defines.events.on_tick, function ()
    renderer = create_renderer()
    rebuild_overlays() -- overwrites on_tick handler
  end)

  -- This ensures the tick function is generated at the same tick on server and clients.
  script.on_event(defines.events.on_player_joined_game, function ()
    renderer = create_renderer()
    rebuild_overlays() -- overwrites on_tick handler
  end)

  local noop = function () end
  script.on_nth_tick(180, noop)
  script.on_event({
    defines.events.on_research_started,
    defines.events.on_research_finished,
    defines.events.on_research_cancelled,
    defines.events.on_player_created,
    defines.events.on_singleplayer_init,
    defines.events.on_player_left_game,
    defines.events.on_player_display_resolution_changed,
    defines.events.on_player_changed_force,
    defines.events.on_multiplayer_init,
    defines.events.on_force_created,
    defines.events.on_forces_merged,
    defines.events.on_script_trigger_effect,
    defines.events.on_object_destroyed,
    defines.events.on_surface_cleared,
    defines.events.on_surface_deleted,
    defines.events.script_raised_teleported,
    defines.events.on_runtime_mod_setting_changed,
  }, noop)
end

function LabControl.on_configuration_changed()
  renderer = create_renderer()
  rebuild_overlays() -- cancels the deferred render registered in on_load

  validate_technology_prototypes()
end

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
