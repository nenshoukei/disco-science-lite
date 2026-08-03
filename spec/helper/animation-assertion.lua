local assert = require("luassert")

--- @class AnimationAssertion
local AnimationAssertion = {}

--- @param expected_frame_index integer
--- @param animation            data.Animation
function AnimationAssertion.frozen(expected_frame_index, animation)
  assert.are_not.same(0, #animation.layers)
  --- @cast animation.layers - nil
  for _, layer in pairs(animation.layers) do
    assert.are.same({ expected_frame_index }, layer.frame_sequence)
    assert.is_nil(layer.repeat_count)
  end
end

--- @param expected_filenames string[]
--- @param animation          data.Animation
function AnimationAssertion.has_layers(expected_filenames, animation)
  assert.are.equal(#expected_filenames, #animation.layers)
  --- @cast animation.layers - nil

  for i = 1, #expected_filenames do
    local expected_filename = expected_filenames[i]

    local layer = animation.layers[i]
    assert.is_not_nil(layer) --- @cast layer - nil
    assert.are.equal(expected_filename, layer.filename)
  end
end

return AnimationAssertion
