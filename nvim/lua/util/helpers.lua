local M = {}

---@param name string
function M.get_plugin(name)
  return require("lazy.core.config").spec.plugins[name]
end

---@param name string
function M.opts(name)
  local plugin = M.get_plugin(name)
  if not plugin then
    return {}
  end
  local Plugin = require("lazy.core.plugin")
  return Plugin.values(plugin, "opts", false)
end

-- Generate UUID-like strings
function M.generate_uuid()
  local template = "xxxx-xxxx-xxxx-xxxx"
  math.randomseed(os.time() + os.clock() * 1000000)

  return string.gsub(template, "x", function()
    return string.format("%x", math.random(0, 15))
  end)
end

return M
