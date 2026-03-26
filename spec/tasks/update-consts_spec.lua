local task = require("tasks.update-consts")

describe("tasks/update-consts", function ()
  local mock_consts = {
    FOO = 123,
    BAR = "hello",
    BAZ = true,
    PI = 3.14,
    ESCAPED = 'quote"inside',
    NAME_PREFIX = "mks-dsl-",
  }

  setup(function ()
    task.set_consts(mock_consts)
  end)

  describe("to_literal", function ()
    it("converts numbers to string", function ()
      assert.equal("123", task.to_literal(123))
      assert.equal("3.14", task.to_literal(3.14))
    end)

    it("converts booleans to string", function ()
      assert.equal("true", task.to_literal(true))
      assert.equal("false", task.to_literal(false))
    end)

    it("converts strings to escaped quoted strings", function ()
      assert.equal('"hello"', task.to_literal("hello"))
      assert.equal('"quote\\"inside"', task.to_literal('quote"inside'))
    end)
  end)

  describe("update_content", function ()
    it("replaces naked constants with tagged literals", function ()
      local input = "local x = consts.FOO"
      local expected = "local x = 123 --[[$FOO]]"
      assert.equal(expected, task.update_content(input))
    end)

    it("updates existing tagged literals", function ()
      local input = "local x = 999 --[[$FOO]]"
      local expected = "local x = 123 --[[$FOO]]"
      assert.equal(expected, task.update_content(input))
    end)

    it("preserves original tag whitespaces", function ()
      local input = "local x = 999\n  --[[$  FOO ]]"
      local expected = "local x = 123\n  --[[$  FOO ]]"
      assert.equal(expected, task.update_content(input))
    end)

    it("preserves comma between literal and tag", function ()
      local input = "local x = {\n  999, --[[$FOO]]\n}"
      local expected = "local x = {\n  123, --[[$FOO]]\n}"
      assert.equal(expected, task.update_content(input))
    end)

    it("handles multiple constants in one file", function ()
      local input = "local x = consts.FOO\nlocal y = consts.BAR"
      local expected = 'local x = 123 --[[$FOO]]\nlocal y = "hello" --[[$BAR]]'
      assert.equal(expected, task.update_content(input))
    end)

    it("handles multiple constants in one line", function ()
      local input = "local x = consts.FOO .. consts.BAR"
      local expected = 'local x = 123 --[[$FOO]] .. "hello" --[[$BAR]]'
      assert.equal(expected, task.update_content(input))
    end)

    it("handles mixed naked and tagged constants", function ()
      local input = "local x = 999 --[[$FOO]]\nlocal y = consts.BAR"
      local expected = 'local x = 123 --[[$FOO]]\nlocal y = "hello" --[[$BAR]]'
      assert.equal(expected, task.update_content(input))
    end)

    it("handles multiple tagged constants in one line", function ()
      local input = 'local x = 999 --[[$FOO]] .. "test" --[[$BAR]]'
      local expected = 'local x = 123 --[[$FOO]] .. "hello" --[[$BAR]]'
      assert.equal(expected, task.update_content(input))
    end)

    it("is idempotent", function ()
      local input = "local x = consts.FOO\nlocal y = 999 --[[$BAR]]"
      local step1 = task.update_content(input)
      local step2 = task.update_content(step1)
      assert.equal(step1, step2)

      -- Verify the result of step1
      local expected = 'local x = 123 --[[$FOO]]\nlocal y = "hello" --[[$BAR]]'
      assert.equal(expected, step1)
    end)

    it("handles complex literals like escaped strings", function ()
      local input = "local s = consts.ESCAPED"
      local expected = 'local s = "quote\\"inside" --[[$ESCAPED]]'
      assert.equal(expected, task.update_content(input))
    end)

    it("handles constants within parentheses or expressions", function ()
      local input = "if (consts.BAZ) then return consts.PI * 2 end"
      local expected = "if (true --[[$BAZ]]) then return 3.14 --[[$PI]] * 2 end"
      assert.equal(expected, task.update_content(input))
    end)

    it("does not replace consts inside require or other strings", function ()
      local input = 'local consts = require("scripts.shared.consts")'
      assert.equal(input, task.update_content(input))
    end)

    it("handles require followed by tagged constant without merging", function ()
      local input = 'local consts = require("scripts.shared.consts")\nname = 999 --[[$FOO]]'
      local expected = 'local consts = require("scripts.shared.consts")\nname = 123 --[[$FOO]]'
      assert.equal(expected, task.update_content(input))
    end)

    it("throws an error when constant is not found", function ()
      local input = "local x = consts.UNKNOWN"
      assert.has_error(function ()
        task.update_content(input)
      end, "Constant not found: consts.UNKNOWN")
    end)

    it("throws an error when constant in tag is not found", function ()
      local input = "local x = 123 --[[$UNKNOWN]]"
      assert.has_error(function ()
        task.update_content(input)
      end, "Constant not found: consts.UNKNOWN")
    end)

    it("evaluates string concatenation expressions", function ()
      local input = 'local x = "old-value" --[[$NAME_PREFIX .. "foo"]]'
      local expected = '"mks-dsl-foo" --[[$NAME_PREFIX .. "foo"]]'
      assert.equal("local x = " .. expected, task.update_content(input))
    end)

    it("evaluates arithmetic expressions", function ()
      local input = "local x = 0 --[[$FOO + 1]]"
      local expected = "local x = 124 --[[$FOO + 1]]"
      assert.equal(expected, task.update_content(input))
    end)

    it("evaluates boolean expressions", function ()
      local input = "local x = false --[[$BAZ]]"
      local expected = "local x = true --[[$BAZ]]"
      assert.equal(expected, task.update_content(input))
    end)

    it("is idempotent with expression tags", function ()
      local input = 'local x = "mks-dsl-foo" --[[$NAME_PREFIX .. "foo"]]'
      local step1 = task.update_content(input)
      local step2 = task.update_content(step1)
      assert.equal(step1, step2)
      assert.equal(input, step1)
    end)

    it("throws an error when expression using non-existent constant", function ()
      local input = 'local x = "v" --[[$UNKNOWN_VAR .. "foo"]]'
      assert.has_error(function ()
        task.update_content(input)
      end, "Constant not found: consts.UNKNOWN_VAR")
    end)

    it("throws an error when expression has syntax error", function ()
      local input = 'local x = "v" --[[$syntax error]]'
      assert.has_error(function ()
        task.update_content(input)
      end, "Failed to compile syntax error: [string \"syntax error\"]:1: <eof> expected near 'error'")
    end)

    it("throws an error when expression returns nil", function ()
      local input = 'local x = "v" --[[$nil]]'
      assert.has_error(function ()
        task.update_content(input)
      end, "Constant expression returned nil: nil")
    end)

    it("throws an error when expression returns a non-literal value", function ()
      -- Tables cannot be embedded as literals
      local input = 'local x = "v" --[[${FOO}]]'
      assert.has_error(function ()
        task.update_content(input)
      end)
    end)
  end)
end)
