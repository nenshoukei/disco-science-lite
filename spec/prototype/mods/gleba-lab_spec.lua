local Helper = require("spec.helper")
local PrototypeLabRegistry = require("scripts.prototype.prototype-lab-registry")

_G.mods["gleba-lab"] = "1.0.0"
local Mod = require("scripts.prototype.mods.gleba-lab")

describe("mods/gleba-lab", function ()
  before_each(function ()
    Helper.reset_mocks()
    PrototypeLabRegistry.reset()
    _G.mods["gleba-lab"] = "1.0.0"
  end)

  -- -------------------------------------------------------------------
  describe("on_data", function ()
    it("registers labs", function ()
      Mod.on_data()
      assert.is_not_nil(PrototypeLabRegistry.registered_labs["glebalab"])
    end)
  end)

  -- -------------------------------------------------------------------
  describe("on_data_final_fixes", function ()
    local on_animation --- @type data.Animation

    before_each(function ()
      -- No public code repositories
      on_animation = {
        layers = {
          { filename = "__gleba-lab__/graphics/entity/GlebaLab.png" },
          { filename = "__gleba-lab__/graphics/entity/GlebaLabPlants.png" },
          { filename = "__gleba-lab__/graphics/entity/GlebaLabLights" },
          { filename = "__gleba-lab__/graphics/entity/GlebaLabShadow" },
        },
      }
      _G.data.raw.lab["glebalab"] = ({ on_animation = on_animation }) --[[@as data.LabPrototype]]
    end)

    it("applies lab modifications", function ()
      Mod.on_data_final_fixes()
      -- TODO: Write assertions
    end)

    it("creates the glebalab overlay animation", function ()
      Mod.on_data_final_fixes()
      local overlay = _G.data.raw["animation"]["mks-dsl-glebalab-overlay"]
      assert.is_not_nil(overlay) --- @cast overlay -nil
    end)
  end)
end)
