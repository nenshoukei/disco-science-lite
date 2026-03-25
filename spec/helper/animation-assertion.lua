local luassert = require("luassert")

local AnimationAssertion = {}

--- @param expected_frame_index integer
--- @param animation data.Animation
function AnimationAssertion.frozen(expected_frame_index, animation)
  luassert.are_not.same(0, #animation.layers)
  for _, layer in pairs(animation.layers) do
    luassert.are.same({ expected_frame_index }, layer.frame_sequence)
    luassert.is_nil(layer.repeat_count)
  end
end

return AnimationAssertion
