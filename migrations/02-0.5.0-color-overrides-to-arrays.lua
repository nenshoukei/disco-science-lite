-- Migrate color_overrides values from ColorTuple to ColorTuple[] (multi-color support)
if storage.color_overrides then
  for name, color in pairs(storage.color_overrides) do
    if type(color[1]) == "number" then
      storage.color_overrides[name] = { color }
    end
  end
end
