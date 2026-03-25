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

--- @param animation data.Animation
function AnimationAssertion.is_vanilla_lab_modifications_applied(animation)
  luassert.are.equal(3, #animation.layers)
  luassert.are.equal("__disco-science-lite__/graphics/factorio/lab-mask.png" --[[$GRAPHICS_DIR .. "factorio/lab-mask.png"]], animation.layers[1].filename)
  luassert.are.equal("__base__/graphics/entity/lab/lab-integration.png", animation.layers[2].filename)
  luassert.are.equal("__base__/graphics/entity/lab/lab-shadow.png", animation.layers[3].filename)
  AnimationAssertion.frozen(1, animation)
end

return AnimationAssertion
