local ui = require("util.ui")

return {
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			{
				-- snippet plugin
				"L3MON4D3/LuaSnip",
				dependencies = "rafamadriz/friendly-snippets",
				opts = { history = true, updateevents = "TextChanged,TextChangedI" },
				config = function(_, opts)
					require("luasnip").config.set_config(opts)
					-- vscode format
					require("luasnip.loaders.from_vscode").lazy_load({ exclude = vim.g.vscode_snippets_exclude or {} })
					require("luasnip.loaders.from_vscode").lazy_load({ paths = vim.g.vscode_snippets_path or "" })

					-- snipmate format
					require("luasnip.loaders.from_snipmate").load()
					require("luasnip.loaders.from_snipmate").lazy_load({ paths = vim.g.snipmate_snippets_path or "" })

					-- lua format
					require("luasnip.loaders.from_lua").load()
					require("luasnip.loaders.from_lua").lazy_load({ paths = vim.g.lua_snippets_path or "" })

					vim.api.nvim_create_autocmd("InsertLeave", {
						callback = function()
							if
								require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
								and not require("luasnip").session.jump_active
							then
								require("luasnip").unlink_current()
							end
						end,
					})
				end,
			},

			-- cmp sources plugins
			{
				"saadparwaiz1/cmp_luasnip",
				"hrsh7th/cmp-nvim-lua",
				"hrsh7th/cmp-nvim-lsp",
				"hrsh7th/cmp-buffer",
				"hrsh7th/cmp-path",
			},
		},
		config = function()
			local cmp = require("cmp")
			local auto_select = true

			cmp.setup(
				{
					window = { completion = { border = ui.border("CmpBorder") } },
					snippet = {
						expand = function(args)
							require("luasnip").lsp_expand(args.body)
						end,
					},
					sources = {
						{ name = "nvim_lsp" },
						{ name = "luasnip" },
						{ name = "buffer" },
						{ name = "nvim_lua" },
						{ name = "path" },
					},
					mapping = cmp.mapping.preset.insert({
						["<C-b>"] = cmp.mapping.scroll_docs(-4),
						["<C-f>"] = cmp.mapping.scroll_docs(4),
						["<C-Space>"] = cmp.mapping.complete(),
						["<CR>"] = cmp.confirm({ select = auto_select }),
						["<C-y>"] = cmp.confirm({ select = true }),
						["<S-CR>"] = cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace }),
						["<C-CR>"] = function(fallback)
							cmp.abort()
							fallback()
						end,
					}),
				},

				vim.diagnostic.config({
					float = {
						focusable = false,
						style = "minimal",
						border = "rounded",
						source = "always",
						header = "",
						prefix = "",
					},
				})
			)
		end,
	},
}
