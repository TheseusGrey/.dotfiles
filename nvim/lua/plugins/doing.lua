return {
  "Hashino/doing.nvim",
  cmd = "Do",
  opts = {
    winbar = { enabled = false },
  },
  keys = {
    {
      "<leader>da",
      function()
        require("doing").add()
      end,
      desc = "Add task to TODO list",
    },
    {
      "<leader>dd",
      function()
        require("doing").done()
      end,
      desc = "Mark a task as done",
    },
    {
      "<leader>de",
      function()
        require("doing").edit()
      end,
      desc = "Edit the task list",
    },
  },
}
