return {
  "stevearc/overseer.nvim",
  opts = {
    task_list = {
      direction = "right",
    },
  },
  keys = {
    { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Run a task through overseer" },
    { "<leader>ol", "<cmd>OverseerToggle<cr>", desc = "Toggle Overseer task list" },
  },
}
