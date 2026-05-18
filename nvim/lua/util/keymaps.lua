local M = {}

---Function for adding keymaps to "find" group
---@param key string
---@return string
function M.find(key)
  return "<leader>f" .. key
end

---Function for adding keymaps to "plugins" group
---@param key string
---@return string
function M.plugin(key)
  return "<leader>P" .. key
end

---Function for adding keymaps to "goto" group
---@param key string
---@return string
function M.go(key)
  return "<leader>g" .. key
end

---Function for adding keymaps to "git" group
---@param key string
---@return string
function M.git(key)
  return "<leader>g" .. key
end

---Function for adding keymaps to "edit" group
---@param key string
---@return string
function M.edit(key)
  return "<leader>e" .. key
end

---Function for adding keymaps to "buffer" group
---@param key string
---@return string
function M.buffer(key)
  return "<leader>b" .. key
end

---Function for adding keymaps to "toggle" group, this is for showing +
---hiding UI elements for the most part
---@param key string
---@return string
function M.toggle(key)
  return "<leader>t" .. key
end

return M
