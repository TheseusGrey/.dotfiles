local function enable_markview_for_presentation()
  require("markview").commands.Enable()

  vim.defer_fn(function()
    local present = require("present")
    local body = present.presentation and present.presentation.windows and present.presentation.windows.body
    if body and body.buf and vim.api.nvim_buf_is_valid(body.buf) then
      vim.api.nvim_create_autocmd("BufLeave", {
        buffer = body.buf,
        once = true,
        callback = function()
          require("markview").commands.Disable()
        end,
      })
    end
  end, 50)
end

return {
  {
    "TheseusGrey/present.nvim",
    dev = true,
    dir = "~/projects/present.nvim",
    dependencies = {
      "OXY2DEV/markview.nvim",
    },
    ft = "markdown",
    opts = {
      integrations = {
        markview = true,
      },
    },

    keys = {
      {
        "<leader>Ps",
        function()
          enable_markview_for_presentation()
          vim.cmd("PresentStart")
        end,
        desc = "Start Presentation",
      },
      {
        "<leader>Pr",
        function()
          enable_markview_for_presentation()
          vim.cmd("PresentResume")
        end,
        desc = "Resume Presentation",
      },
    },
  },
  { -- for pretty markdown styling
    "OXY2DEV/markview.nvim",
    dependencies = {
      "saghen/blink.cmp",
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = true,
    ft = { "codecompanion", "avante" },
    priority = 49,
    config = function()
      local presets = require("markview.presets")
      vim.g.markview_blink_loaded = true

      require("markview").setup({
        preview = {
          enable = false,
          filetypes = { "codecompanion", "avante" },
          ignore_buftypes = { "markdown" },
        },
        markdown = {
          horizontal_rules = presets.horizontal_rules.thin,
          headings = presets.headings.marker,
        },
      })
    end,
  },
}
