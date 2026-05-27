local serialize = require("util.snippet-creator.serialize")
local shared = require("util.snippet-creator.state")

describe("snippet-creator serialize", function()
  before_each(function()
    shared.state = nil
  end)

  after_each(function()
    shared.state = nil
  end)

  describe("format_text_node", function()
    it("formats single line text", function()
      local result = serialize.format_text_node("hello")
      assert.equals('    t("hello"),', result)
    end)

    it("formats multiline text", function()
      local result = serialize.format_text_node("line1\nline2")
      assert.equals('    t({ "line1", "line2" }),', result)
    end)

    it("escapes special characters in text", function()
      local result = serialize.format_text_node('say "hi"')
      assert.truthy(result:match("\\"))
    end)

    it("handles empty string", function()
      local result = serialize.format_text_node("")
      assert.equals('    t(""),', result)
    end)

    it("handles string with only newline", function()
      local result = serialize.format_text_node("\n")
      assert.equals('    t({ "", "" }),', result)
    end)

    it("handles three lines", function()
      local result = serialize.format_text_node("a\nb\nc")
      assert.equals('    t({ "a", "b", "c" }),', result)
    end)
  end)

  describe("format_node", function()
    it("formats insert_node", function()
      local node = { type = "insert_node", text = "placeholder", config = {} }
      local result = serialize.format_node(node, 1)
      assert.equals('    i(1, "placeholder"),', result)
    end)

    it("formats choice_node with choices", function()
      local node = { type = "choice_node", text = "a", config = { choices = { "a", "b", "c" } } }
      local result = serialize.format_node(node, 2)
      assert.equals('    c(2, { t("a"), t("b"), t("c") }),', result)
    end)

    it("formats choice_node without config falls back to text", function()
      local node = { type = "choice_node", text = "fallback", config = {} }
      local result = serialize.format_node(node, 1)
      assert.equals('    c(1, { t("fallback") }),', result)
    end)

    it("formats function_node", function()
      local node = { type = "function_node", text = "x", config = { body = "return args[1][1]", deps = { 1, 2 } } }
      local result = serialize.format_node(node, 3)
      assert.equals('    f(function(args) return args[1][1] end, { 1, 2 }),', result)
    end)

    it("formats rep node", function()
      local node = { type = "rep", text = "x", config = { target = 2 } }
      local result = serialize.format_node(node, 4)
      assert.equals("    rep(2),", result)
    end)

    it("formats dynamic_node", function()
      local node = { type = "dynamic_node", text = "default", config = { deps = { 1 }, inner_text = "inner" } }
      local result = serialize.format_node(node, 2)
      assert.equals('    d(2, function(args) return sn(nil, { i(1, "inner") }) end, { 1 }),', result)
    end)

    it("formats text_node", function()
      local node = { type = "text_node", text = "static", config = {} }
      local result = serialize.format_node(node, 1)
      assert.equals('    t("static"),', result)
    end)

    it("formats unknown type as insert_node fallback", function()
      local node = { type = "bogus_type", text = "wat", config = {} }
      local result = serialize.format_node(node, 5)
      assert.equals('    i(5, "wat"),', result)
    end)

    it("handles text with quotes in insert_node", function()
      local node = { type = "insert_node", text = 'say "hi"', config = {} }
      local result = serialize.format_node(node, 1)
      -- Should escape the quotes
      assert.truthy(result:match('i%(1,'))
      assert.truthy(result:match("\\"))
    end)

    it("handles empty deps in function_node", function()
      local node = { type = "function_node", text = "x", config = { body = "return 'hi'", deps = {} } }
      local result = serialize.format_node(node, 1)
      assert.equals("    f(function(args) return 'hi' end, {  }),", result)
    end)
  end)

  describe("serialize_snippet", function()
    it("returns empty string when state is nil", function()
      shared.state = nil
      assert.equals("", serialize.serialize_snippet())
    end)

    it("serializes a simple snippet with one insert_node", function()
      shared.state = {
        lines = { "hello world" },
        nodes = {
          {
            type = "insert_node",
            start_row = 0,
            start_col = 6,
            end_row = 0,
            end_col = 11,
            text = "world",
            index = 1,
            config = {},
          },
        },
        meta = { trigger = "hw", name = "Hello World", description = "says hello" },
      }

      local result = serialize.serialize_snippet()
      -- Should contain the trigger, name, description
      assert.truthy(result:match('trig = "hw"'))
      assert.truthy(result:match('name = "Hello World"'))
      assert.truthy(result:match('dscr = "says hello"'))
      -- Should have text before the node
      assert.truthy(result:match('t%("hello "%)'))
      -- Should have the insert node
      assert.truthy(result:match('i%(1, "world"%)'))
      -- Should end with i(0)
      assert.truthy(result:match("i%(0%)"))
    end)

    it("serializes snippet without description", function()
      shared.state = {
        lines = { "test" },
        nodes = {},
        meta = { trigger = "tst", name = "Test", description = "" },
      }

      local result = serialize.serialize_snippet()
      assert.falsy(result:match("dscr"))
    end)

    it("serializes multiline snippet correctly", function()
      shared.state = {
        lines = { "line1", "line2" },
        nodes = {
          {
            type = "insert_node",
            start_row = 1,
            start_col = 0,
            end_row = 1,
            end_col = 5,
            text = "line2",
            index = 1,
            config = {},
          },
        },
        meta = { trigger = "ml", name = "Multiline", description = "" },
      }

      local result = serialize.serialize_snippet()
      -- Text before node spans newline: "line1\n"
      assert.truthy(result:match('t%(%{'))
    end)

    it("handles adjacent nodes with no text between them", function()
      shared.state = {
        lines = { "ab" },
        nodes = {
          {
            type = "insert_node",
            start_row = 0,
            start_col = 0,
            end_row = 0,
            end_col = 1,
            text = "a",
            index = 1,
            config = {},
          },
          {
            type = "insert_node",
            start_row = 0,
            start_col = 1,
            end_row = 0,
            end_col = 2,
            text = "b",
            index = 2,
            config = {},
          },
        },
        meta = { trigger = "ab", name = "Adjacent", description = "" },
      }

      local result = serialize.serialize_snippet()
      -- Should have two insert nodes with no text between
      assert.truthy(result:match('i%(1, "a"%)'))
      assert.truthy(result:match('i%(2, "b"%)'))
    end)

    it("handles node at very start of text", function()
      shared.state = {
        lines = { "hello" },
        nodes = {
          {
            type = "insert_node",
            start_row = 0,
            start_col = 0,
            end_row = 0,
            end_col = 5,
            text = "hello",
            index = 1,
            config = {},
          },
        },
        meta = { trigger = "h", name = "Hello", description = "" },
      }

      local result = serialize.serialize_snippet()
      -- No text before the node, should start with insert_node directly
      assert.truthy(result:match('i%(1, "hello"%)'))
      -- There should be no t("") empty text node before it
      -- Actually, let's check: if node_start (0) > pos (0), text_between is skipped
      -- So we should NOT have an empty text node
    end)

    it("preserves node ordering by position", function()
      shared.state = {
        lines = { "foo bar baz" },
        nodes = {
          -- Intentionally out of order in the list
          {
            type = "insert_node",
            start_row = 0,
            start_col = 8,
            end_row = 0,
            end_col = 11,
            text = "baz",
            index = 2,
            config = {},
          },
          {
            type = "insert_node",
            start_row = 0,
            start_col = 0,
            end_row = 0,
            end_col = 3,
            text = "foo",
            index = 1,
            config = {},
          },
        },
        meta = { trigger = "fbb", name = "FooBarBaz", description = "" },
      }

      local result = serialize.serialize_snippet()
      -- After sorting, foo should be position 1, baz should be position 2
      local foo_pos = result:find('i%(1, "foo"%)')
      local baz_pos = result:find('i%(2, "baz"%)')
      assert.is_not_nil(foo_pos)
      assert.is_not_nil(baz_pos)
      assert.truthy(foo_pos < baz_pos)
    end)

    it("handles rep node serialization in context", function()
      shared.state = {
        lines = { "foo = foo" },
        nodes = {
          {
            type = "insert_node",
            start_row = 0,
            start_col = 0,
            end_row = 0,
            end_col = 3,
            text = "foo",
            index = 1,
            config = {},
          },
          {
            type = "rep",
            start_row = 0,
            start_col = 6,
            end_row = 0,
            end_col = 9,
            text = "foo",
            index = 2,
            config = { target = 1 },
          },
        },
        meta = { trigger = "rep", name = "RepTest", description = "" },
      }

      local result = serialize.serialize_snippet()
      assert.truthy(result:match('i%(1, "foo"%)'))
      assert.truthy(result:match("rep%(1%)"))
      -- text between: " = "
      assert.truthy(result:match('t%(" = "%)'))
    end)
  end)
end)


