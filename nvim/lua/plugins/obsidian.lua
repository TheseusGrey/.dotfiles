local vault_location = vim.fn.expand("~") .. "/Documents/Lore Store"

return {
  {
    "oflisback/obsidian-bridge.nvim",
    opts = {
      obsidian_server_address = "https://127.0.0.1:27124",
      cert_path = "~/Documents/obsidian.crt",
    },
    event = {
      "BufReadPre " .. vault_location .. "/**.md",
      "BufNewFile " .. vault_location .. "/**.md",
    },
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
  },
}
