return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },

    -- example using `opts` for defining servers
    opts = {
      servers = {
        lua_ls = {},
      },
    },
    config = function(_, opts)
      local lspconfig = require("lspconfig")
      for server, config in pairs(opts.servers) do
        -- passing config.capabilities to blink.cmp merges with the capabilities in your
        -- `opts[server].capabilities, if you've defined it
        config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
        lspconfig[server].setup(config)
      end
    end,
  },
}

-- return {
--   {
--     "neovim/nvim-lspconfig",
--     dependencies = {
--       "mason.nvim",
--       "saghen/blink.cmp",
--       "williamboman/mason-lspconfig.nvim",
--     },
--     opts = {
--       fuzzy = { implementation = "prefer_rust_with_warning" },
--       servers = {
--         lua_ls = {
--           settings = {
--             Lua = {
--               workspace = {
--                 checkThirdParty = false,
--               },
--               codeLens = {
--                 enable = true,
--               },
--               completion = {
--                 callSnippet = "Replace",
--               },
--               doc = {
--                 privateName = { "^_" },
--               },
--               hint = {
--                 enable = true,
--                 setType = false,
--                 paramType = true,
--                 paramName = "Disable",
--                 semicolon = "Disable",
--                 arrayIndex = "Disable",
--               },
--             },
--           },
--         },
--       },
--     },
--     config = function(_, opts)
--       local lspconfig = require("lspconfig")
--       for server, config in pairs(opts.servers) do
--         -- passing config.capabilities to blink.cmp merges with the capabilities in your
--         -- `opts[server].capabilities, if you've defined it
--         config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
--         lspconfig[server].setup(config)
--       end
--     end,
--   },
--   {
--     "williamboman/mason.nvim",
--     cmd = "Mason",
--     keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
--     build = ":MasonUpdate",
--     opts_extend = { "ensure_installed" },
--     opts = {
--       ensure_installed = {
--         "stylua",
--         "shfmt",
--       },
--     },
--     ---@param opts MasonSettings | {ensure_installed: string[]}
--     config = function(_, opts)
--       require("mason").setup(opts)
--       local mr = require("mason-registry")
--       mr:on("package:install:success", function()
--         vim.defer_fn(function()
--           -- trigger FileType event to possibly load this newly installed LSP server
--           require("lazy.core.handler.event").trigger({
--             event = "FileType",
--             buf = vim.api.nvim_get_current_buf(),
--           })
--         end, 100)
--       end)
--
--       mr.refresh(function()
--         for _, tool in ipairs(opts.ensure_installed) do
--           local p = mr.get_package(tool)
--           if not p:is_installed() then
--             p:install()
--           end
--         end
--       end)
--     end,
--   },
--   { "mfussenegger/nvim-jdtls", ft = { "java" }, dependencies = {
--     "nvim-dap",
--   } },
-- }
