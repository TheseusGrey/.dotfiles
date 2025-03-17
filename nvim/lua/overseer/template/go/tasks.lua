local constants = require("overseer.constants")
local log = require("overseer.log")
local overseer = require("overseer")
local TAG = constants.TAG

---@type overseer.TemplateFileDefinition
local tmpl = {
  name = "go",
  priority = 60,
  tags = { TAG.BUILD },
  params = {
    args = { optional = true, type = "list", delimiter = " " },
    cwd = { optional = true },
  },
  builder = function(params)
    return {
      cmd = { "go" },
      args = params.args,
      cwd = params.cwd,
    }
  end,
}

local supported_tasks = {
  { "test" },
  { "run", "," },
  { "mod", "tidy" },
}

---@param opts overseer.SearchParams
---@return nil|string
local function get_go_mod(opts)
  return vim.fs.find("go.mod", { upward = true, type = "file", path = opts.dir })[1]
end

---@type overseer.TemplateFileProvider
local provider = {
  cache_key = function(opts)
    return get_go_mod(opts)
  end,
  condition = {
    callback = function(opts)
      if vim.fn.executable("go") == 0 then
        return false, 'Command "go" not found'
      end
      if not get_go_mod(opts) then
        return false, "No go.mod file found"
      end
      return true
    end,
  },
  generator = function(opts, cb)
    local go_mod = assert(get_go_mod(opts))
    local cwd = vim.fs.dirname(go_mod)

    local ret = {}
    for _, task_args in ipairs(supported_tasks) do
      table.insert(ret, overseer.wrap_template(tmpl, nil, { cwd = cwd, args = task_args }))
    end

    cb(ret)
  end,
}
return provider
