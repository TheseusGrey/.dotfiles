require("lazydev").setup({
  library = {
    -- Load luvit types when vim.uv is used
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    -- Uncomment to always load the vim runtime types:
    -- vim.env.VIMRUNTIME,
  },
})
