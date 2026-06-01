local M = {}

local ft_callbacks = {}

---Registers a plugin setup to run before entering a given filetype(s)
---Useful for "lazy loading" plugins you don't want running until you need them
---@param filetypes string[]
---@param callback function
function M.on_file_extension(filetypes, callback)
  for i, ft in ipairs(filetypes) do
    if vim.tbl_contains(ft_callbacks, ft) then
      ft_callbacks[i].insert(ft, callback)
    else
      ft_callbacks.insert(ft, { callback })
    end
  end
end

function M.register_filetype_callbacks()
  for index, ft in ipairs(ft_callbacks) do
    vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
      pattern = "*." .. ft,
      once = true,
      callback = function()
        for _, cb in ipairs(ft_callbacks[index]) do
          cb()
        end
      end,
    })
  end
end

return M
