--- Rendering mock: draw_animation returns a mock LuaRenderObject.
--- @diagnostic disable-next-line: missing-fields
_G.rendering = {
  objects = {},
  next_id = 1,
  clear = function ()
    _G.rendering.objects = {}
  end,
  get_all_objects = function (mod_name)
    local objects = {}
    for _, obj in pairs(_G.rendering.objects) do
      objects[#objects + 1] = obj
    end
    return objects
  end,
  draw_animation = function (params)
    local id = _G.rendering.next_id
    _G.rendering.next_id = id + 1
    --- destroy() is called without self (dot notation), so use a closure.
    local obj = {
      id               = id,
      valid            = true,
      visible          = false,
      color            = { 0, 0, 0 },
      surface          = params.surface,
      target           = { entity = params.target },
      animation        = params.animation,
      x_scale          = params.x_scale,
      y_scale          = params.y_scale,
      animation_offset = params.animation_offset,
    }
    obj.destroy = function ()
      obj.valid = false
      _G.rendering.objects[id] = nil
    end
    _G.rendering.objects[id] = obj
    return obj --[[@as LuaRenderObject]]
  end,
}
