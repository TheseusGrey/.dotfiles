return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup({})

    -- basic telescope configuration
    local conf = require("telescope.config").values
    local function toggle_telescope(harpoon_files)
      local file_paths = {}
      for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
      end

      require("telescope.pickers")
        .new({}, {
          prompt_title = "Harpoon",
          previewer = conf.file_previewer({}),
          sorter = conf.generic_sorter({}),
          finder = require("telescope.finders").new_table({
            results = file_paths,
          }),
        })
        :find()
    end
    vim.keymap.set("n", "<leader>ha", function()
      harpoon:list():add()
    end, { desc = "Add mark to harpoon" })
    vim.keymap.set("n", "<leader>hl", function()
      toggle_telescope(harpoon:list())
    end, { desc = "Open harpoon window" })
    vim.keymap.set("n", "<leader>hq", function()
      harpoon:list():select(1)
    end, { desc = "Go to first harpoon mark" })
    vim.keymap.set("n", "<leader>hw", function()
      harpoon:list():select(2)
    end, { desc = "Go to second harpoon mark" })
    vim.keymap.set("n", "<leader>he", function()
      harpoon:list():select(3)
    end, { desc = "Go to third harpoon mark" })
    vim.keymap.set("n", "<leader>hr", function()
      harpoon:list():select(4)
    end, { desc = "Go to forth harpoon mark" })
  end,
}
