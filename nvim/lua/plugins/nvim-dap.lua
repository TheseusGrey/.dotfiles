local breakpoints = {
  stop = { text = "󱡝", texthl = "Error", linehl = "", numhl = "" },
}

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
    },
    lazy = true,
    config = function(opts)
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()

      vim.fn.sign_define("DapBreakpoint", breakpoints.stop)
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end
    end,
    keys = {
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle Breakpoint",
      },
      { "<leader>dh", "<cmd>DapStepOut<cr>", desc = "Step out" },
      { "<leader>dl", "<cmd>DapStepInto<cr>", desc = "Step into" },
      { "<leader>dj", "<cmd>DapStepOver<cr>", desc = "Step over" },
      { "<leader>dk", "<cmd>DapContinue<cr>", desc = "Kontinue" },
    },
  },
  { "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } },
}
