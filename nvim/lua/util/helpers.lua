local M = {}

---Checks if nvim is currently running inside a git repo
---@return boolean
function M.is_git_repo()
  vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null")
  return vim.v.shell_error == 0
end

---Checks if nvim is currently running inside a obsidian vault
---@return boolean
function M.is_obsidian_vault()
  return vim.fn.isdirectory(vim.fn.getcwd() .. "/.obsidian") == 1
end

--- Prepends a plugin path with the github url
---@param x string
---@return string
function M.gh(x)
  return "https://github.com/" .. x
end

--- Generates a UUID-like string, useful for semi unique keys
---@return string
function M.generate_uuid()
  local template = "xxxx-xxxx-xxxx-xxxx"
  math.randomseed(os.time() + os.clock() * 1000000)

  return string.gsub(template, "x", function()
    return string.format("%x", math.random(0, 15))
  end)
end

return M
