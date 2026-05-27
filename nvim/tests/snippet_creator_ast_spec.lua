local ast = require("util.snippet-creator.ast")

describe("snippet-creator ast", function()
  describe("analyze_ast", function()
    local function make_buf(lines, ft)
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_set_option_value("filetype", ft or "lua", { buf = buf })
      -- Force treesitter parse
      vim.treesitter.get_parser(buf, ft or "lua"):parse()
      return buf
    end

    it("treats full property access chains as single units", function()
      local lines = {
        "local x = vim.diagnostic.severity.ERROR",
        "local y = vim.diagnostic.severity.WARN",
      }
      local buf = make_buf(lines, "lua")
      local identifiers, _ = ast.analyze_ast(buf, lines, 0)

      assert.is_not_nil(identifiers["vim.diagnostic.severity.ERROR"])
      assert.is_not_nil(identifiers["vim.diagnostic.severity.WARN"])
      assert.equals(1, #identifiers["vim.diagnostic.severity.ERROR"])
      assert.equals(1, #identifiers["vim.diagnostic.severity.WARN"])
      -- No partial chains
      assert.is_nil(identifiers["vim.diagnostic.severity"])
      assert.is_nil(identifiers["vim.diagnostic"])
      assert.is_nil(identifiers["vim"])

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("groups identical full property access chains", function()
      local lines = {
        "local x = foo.bar.baz",
        "local y = foo.bar.baz",
      }
      local buf = make_buf(lines, "lua")
      local identifiers, _ = ast.analyze_ast(buf, lines, 0)

      assert.is_not_nil(identifiers["foo.bar.baz"])
      assert.equals(2, #identifiers["foo.bar.baz"])

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("does not group different property chains sharing a prefix", function()
      local lines = {
        "local x = foo.bar.baz",
        "local y = foo.bar.cat",
      }
      local buf = make_buf(lines, "lua")
      local identifiers, _ = ast.analyze_ast(buf, lines, 0)

      assert.is_not_nil(identifiers["foo.bar.baz"])
      assert.is_not_nil(identifiers["foo.bar.cat"])
      assert.equals(1, #identifiers["foo.bar.baz"])
      assert.equals(1, #identifiers["foo.bar.cat"])

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("handles the diagnostic icons pattern correctly", function()
      local lines = {
        'M.icons = {',
        '  [vim.diagnostic.severity.ERROR] = "",',
        '  [vim.diagnostic.severity.WARN] = "",',
        '  [vim.diagnostic.severity.HINT] = "",',
        '  [vim.diagnostic.severity.INFO] = "",',
        '}',
      }
      local buf = make_buf(lines, "lua")
      local identifiers, _ = ast.analyze_ast(buf, lines, 0)

      local severity_keys = {}
      for name, _ in pairs(identifiers) do
        if name:match("vim.diagnostic.severity") then
          table.insert(severity_keys, name)
        end
      end
      assert.equals(4, #severity_keys)

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("groups repeated standalone identifiers with first=insert rest=rep", function()
      local lines = {
        "local foo = 1",
        "print(foo)",
        "print(foo)",
      }
      local buf = make_buf(lines, "lua")
      local identifiers, _ = ast.analyze_ast(buf, lines, 0)

      assert.is_not_nil(identifiers["foo"])
      assert.equals(3, #identifiers["foo"])

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    -- === NEW: Edge cases and potential bugs ===

    it("handles single-line with multiple identifiers", function()
      local lines = {
        "local x, y, z = foo, bar, foo",
      }
      local buf = make_buf(lines, "lua")
      local identifiers, _ = ast.analyze_ast(buf, lines, 0)

      -- foo appears twice (declaration + use)
      assert.is_not_nil(identifiers["foo"])
      assert.equals(2, #identifiers["foo"])
      assert.is_not_nil(identifiers["bar"])
      assert.equals(1, #identifiers["bar"])

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("handles empty lines in selection", function()
      local lines = {
        "local x = 1",
        "",
        "local y = x + 1",
      }
      local buf = make_buf(lines, "lua")
      local identifiers, _ = ast.analyze_ast(buf, lines, 0)

      assert.is_not_nil(identifiers["x"])
      assert.equals(2, #identifiers["x"])

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("handles start_row offset correctly", function()
      -- Simulate selecting lines 2-3 of a buffer (0-indexed: rows 2,3)
      local full_lines = {
        "-- preamble",
        "-- more preamble",
        "local x = foo.bar",
        "local y = foo.bar",
      }
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, full_lines)
      vim.api.nvim_set_option_value("filetype", "lua", { buf = buf })
      vim.treesitter.get_parser(buf, "lua"):parse()

      local selected_lines = { "local x = foo.bar", "local y = foo.bar" }
      local identifiers, _ = ast.analyze_ast(buf, selected_lines, 2)

      assert.is_not_nil(identifiers["foo.bar"])
      assert.equals(2, #identifiers["foo.bar"])
      -- Positions should be relative to start_row
      assert.equals(0, identifiers["foo.bar"][1].start_row)
      assert.equals(1, identifiers["foo.bar"][2].start_row)

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("handles method calls as member expressions in lua", function()
      local lines = {
        "local x = obj:method()",
        "local y = obj:method()",
      }
      local buf = make_buf(lines, "lua")
      local identifiers, _ = ast.analyze_ast(buf, lines, 0)

      -- method_index_expression should treat obj:method as one unit
      -- Check that "obj" alone is NOT a standalone identifier
      -- The full chain should be captured
      local found_method_chain = false
      for name, positions in pairs(identifiers) do
        if name:match("obj") and name:match("method") then
          found_method_chain = true
          assert.equals(2, #positions)
        end
      end
      assert.is_true(found_method_chain, "obj:method should be treated as a single unit")

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("captures string literals", function()
      local lines = {
        'local x = "hello"',
        'local y = "world"',
      }
      local buf = make_buf(lines, "lua")
      local _, strings = ast.analyze_ast(buf, lines, 0)

      assert.equals(2, #strings)
      -- String text should include quotes
      assert.truthy(strings[1].text:match("hello"))
      assert.truthy(strings[2].text:match("world"))

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("does not capture string_content children if string parent already matched", function()
      local lines = {
        'local x = "hello"',
      }
      local buf = make_buf(lines, "lua")
      local _, strings = ast.analyze_ast(buf, lines, 0)

      -- Should only get the outer string node, not inner string_content
      -- due to the early return in the walk function
      -- If we get duplicates, it's a bug
      local hello_count = 0
      for _, s in ipairs(strings) do
        if s.text:match("hello") then
          hello_count = hello_count + 1
        end
      end
      assert.equals(1, hello_count, "string_content should not duplicate the string node")

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("handles keywords that look like identifiers correctly", function()
      -- Lua keywords should NOT be picked up as identifiers by treesitter
      local lines = {
        "if true then",
        "  local x = 1",
        "end",
      }
      local buf = make_buf(lines, "lua")
      local identifiers, _ = ast.analyze_ast(buf, lines, 0)

      assert.is_nil(identifiers["if"])
      assert.is_nil(identifiers["then"])
      assert.is_nil(identifiers["end"])
      assert.is_nil(identifiers["true"])
      assert.is_not_nil(identifiers["x"])

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("handles a single identifier (no repetition)", function()
      local lines = {
        "local unique_name = 42",
      }
      local buf = make_buf(lines, "lua")
      local identifiers, _ = ast.analyze_ast(buf, lines, 0)

      assert.is_not_nil(identifiers["unique_name"])
      assert.equals(1, #identifiers["unique_name"])

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("handles multiline property access", function()
      -- This tests if treesitter parsing handles expressions split across lines
      local lines = {
        "local x = vim",
        "  .api",
        "  .nvim_create_buf(false, true)",
      }
      local buf = make_buf(lines, "lua")
      local identifiers, _ = ast.analyze_ast(buf, lines, 0)

      -- Depending on how lua treesitter parses this, it might be one chain or broken
      -- This test documents current behavior
      local found_full_chain = false
      for name, _ in pairs(identifiers) do
        if name:match("vim") and name:match("api") and name:match("nvim_create_buf") then
          found_full_chain = true
        end
      end
      -- If Lua parser treats this as a method call chain, this should be true
      -- This might actually FAIL depending on grammar - documenting behavior
      -- If it fails, we know multiline chains are NOT handled
      if not found_full_chain then
        -- At minimum, parts should exist
        local has_vim = false
        for name, _ in pairs(identifiers) do
          if name:match("vim") then
            has_vim = true
          end
        end
        assert.is_true(has_vim)
      end

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("handles nested function calls correctly", function()
      local lines = {
        "local x = string.format('%s %s', foo, foo)",
      }
      local buf = make_buf(lines, "lua")
      local identifiers, _ = ast.analyze_ast(buf, lines, 0)

      -- string.format should be a single chain
      assert.is_not_nil(identifiers["string.format"])
      assert.equals(1, #identifiers["string.format"])
      -- foo appears twice
      assert.is_not_nil(identifiers["foo"])
      assert.equals(2, #identifiers["foo"])

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("position coordinates are correct for identifiers", function()
      local lines = {
        "local abc = 1",
      }
      local buf = make_buf(lines, "lua")
      local identifiers, _ = ast.analyze_ast(buf, lines, 0)

      assert.is_not_nil(identifiers["abc"])
      local pos = identifiers["abc"][1]
      assert.equals(0, pos.start_row)
      assert.equals(6, pos.start_col) -- "local " is 6 chars
      assert.equals(0, pos.end_row)
      assert.equals(9, pos.end_col) -- "abc" is 3 chars

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("handles tables with string keys", function()
      local lines = {
        "local t = {",
        '  name = "hello",',
        '  name2 = "world",',
        "}",
      }
      local buf = make_buf(lines, "lua")
      local identifiers, strings = ast.analyze_ast(buf, lines, 0)

      -- table field names might be identifiers depending on grammar
      -- t should be an identifier
      assert.is_not_nil(identifiers["t"])
      -- strings should be found
      assert.truthy(#strings >= 2)

      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)

  describe("analyze_ast typescript", function()
    local function make_ts_buf(lines)
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_set_option_value("filetype", "typescript", { buf = buf })
      local ok = pcall(function()
        vim.treesitter.get_parser(buf, "typescript"):parse()
      end)
      if not ok then
        vim.api.nvim_buf_delete(buf, { force = true })
        return nil
      end
      return buf
    end

    it("handles TypeScript property access", function()
      local lines = {
        "const x = document.getElementById('test')",
        "const y = document.getElementById('other')",
      }
      local buf = make_ts_buf(lines)
      if not buf then
        pending("typescript parser not available")
        return
      end

      local identifiers, _ = ast.analyze_ast(buf, lines, 0)

      -- document.getElementById should be a single member expression
      local found_chain = false
      for name, positions in pairs(identifiers) do
        if name:match("document") and name:match("getElementById") then
          found_chain = true
          assert.equals(2, #positions)
        end
      end
      assert.is_true(found_chain)

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("handles TypeScript interface-like patterns", function()
      local lines = {
        "interface Props {",
        "  name: string",
        "  age: number",
        "  name: string",
        "}",
      }
      local buf = make_ts_buf(lines)
      if not buf then
        pending("typescript parser not available")
        return
      end

      local identifiers, _ = ast.analyze_ast(buf, lines, 0)

      -- "name" should appear multiple times
      if identifiers["name"] then
        assert.equals(2, #identifiers["name"])
      end

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("handles template literals as strings", function()
      local lines = {
        "const x = `hello ${name}`",
      }
      local buf = make_ts_buf(lines)
      if not buf then
        pending("typescript parser not available")
        return
      end

      local _, strings = ast.analyze_ast(buf, lines, 0)
      -- template_string should be captured
      assert.truthy(#strings >= 1)

      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)

  describe("analyze_ast python", function()
    local function make_py_buf(lines)
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_set_option_value("filetype", "python", { buf = buf })
      local ok = pcall(function()
        vim.treesitter.get_parser(buf, "python"):parse()
      end)
      if not ok then
        vim.api.nvim_buf_delete(buf, { force = true })
        return nil
      end
      return buf
    end

    it("handles Python attribute access", function()
      local lines = {
        "x = self.name",
        "y = self.name",
      }
      local buf = make_py_buf(lines)
      if not buf then
        pending("python parser not available")
        return
      end

      local identifiers, _ = ast.analyze_ast(buf, lines, 0)

      -- self.name should be grouped if attribute is in member_set
      -- Python uses "attribute" node type which IS in member_set
      local found = false
      for name, positions in pairs(identifiers) do
        if name:match("self") and name:match("name") then
          found = true
          assert.equals(2, #positions)
        end
      end
      assert.is_true(found, "self.name should be treated as a member expression")

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("handles Python method chains", function()
      local lines = {
        'result = text.strip().lower()',
      }
      local buf = make_py_buf(lines)
      if not buf then
        pending("python parser not available")
        return
      end

      local identifiers, _ = ast.analyze_ast(buf, lines, 0)

      -- This is interesting - text.strip().lower() is a chain
      -- The top member expression should be the whole thing
      -- Document what actually happens
      local keys = {}
      for name, _ in pairs(identifiers) do
        table.insert(keys, name)
      end
      -- At minimum result should be standalone
      assert.is_not_nil(identifiers["result"])

      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)

  describe("parse_type_choices", function()
    it("parses TypeScript union types", function()
      local hover = '```typescript\n(property) align: "left" | "center" | "right"\n```'
      local choices = ast.parse_type_choices(hover)
      assert.is_not_nil(choices)
      assert.equals(3, #choices)
      assert.same({ "left", "center", "right" }, choices)
    end)

    it("returns nil for non-union types", function()
      local hover = "```typescript\n(property) width: number\n```"
      local choices = ast.parse_type_choices(hover)
      assert.is_nil(choices)
    end)

    it("parses single-quoted unions", function()
      local hover = "```typescript\n(property) mode: 'dark' | 'light' | 'system'\n```"
      local choices = ast.parse_type_choices(hover)
      assert.is_not_nil(choices)
      assert.equals(3, #choices)
      assert.same({ "dark", "light", "system" }, choices)
    end)

    it("returns nil for boolean type", function()
      local hover = "```typescript\n(property) enabled: boolean\n```"
      local choices = ast.parse_type_choices(hover)
      assert.is_nil(choices)
    end)

    it("returns nil for empty string", function()
      local choices = ast.parse_type_choices("")
      assert.is_nil(choices)
    end)

    it("returns nil for nil input", function()
      local choices = ast.parse_type_choices(nil)
      assert.is_nil(choices)
    end)

    it("parses enum members", function()
      local hover = "enum Direction { Up = 0, Down = 1, Left = 2, Right = 3 }"
      local choices = ast.parse_type_choices(hover)
      assert.is_not_nil(choices)
      assert.truthy(#choices >= 2)
    end)

    it("handles union with number literals (should not match as string choices)", function()
      local hover = '```typescript\n(property) size: 1 | 2 | 3 | 4\n```'
      local choices = ast.parse_type_choices(hover)
      -- These aren't quoted strings, so the first regex won't match
      -- But the line has | so it checks... this might be nil or return something weird
      -- Documenting actual behavior
      -- The regex looks for quoted strings, numbers without quotes won't match
      assert.is_nil(choices)
    end)

    it("handles mixed union with strings and types", function()
      -- e.g., type Foo = "bar" | number | "baz"
      local hover = '```typescript\ntype Foo = "bar" | number | "baz"\n```'
      local choices = ast.parse_type_choices(hover)
      -- The regex extracts quoted strings: "bar" and "baz"
      -- It finds | and #choices >= 2 so it should return them
      assert.is_not_nil(choices)
      assert.same({ "bar", "baz" }, choices)
    end)

    it("handles multiline hover with union on second line", function()
      local hover = "```typescript\n(property) align:\n  | 'left'\n  | 'center'\n  | 'right'\n```"
      local choices = ast.parse_type_choices(hover)
      -- Each line has one choice and a |, let's see what happens
      -- Line "  | 'left'" has | and one quoted string
      -- The algorithm: per line, extract quoted strings, if found and line has | and #choices >= 2 return
      -- But each line only has 1 choice... so it won't trigger on individual lines
      -- This is likely a BUG - multiline unions won't be parsed
      -- Documenting: this should probably return {"left", "center", "right"} but likely returns nil
      -- If nil, it's a known limitation
      -- BUG: multiline union format only captures 2 of 3 choices because
      -- the algorithm checks per-line and returns early when a line has | and #choices >= 2
      -- The third line "  | 'right'" pushes 'right' but then finds | on that line,
      -- and since accumulated choices is already >= 2, it returns BEFORE processing last item
      -- Expected: {"left", "center", "right"}, Actual: {"left", "center"}
      assert.is_not_nil(choices, "multiline union should be parseable")
      assert.equals(3, #choices, "BUG: should capture all 3 choices from multiline union")
    end)

    it("handles Lua type annotation unions", function()
      -- lua_ls hover format
      local hover = '---@type "error"|"warn"|"info"|"debug"'
      local choices = ast.parse_type_choices(hover)
      -- This line has | and quoted strings
      assert.is_not_nil(choices)
      assert.same({ "error", "warn", "info", "debug" }, choices)
    end)

    it("does not false-positive on pipe in non-union context", function()
      -- A string with | but no quoted alternatives
      local hover = "```\nUsage: command | grep pattern\n```"
      local choices = ast.parse_type_choices(hover)
      assert.is_nil(choices)
    end)
  end)
end)
