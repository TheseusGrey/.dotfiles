local dap = require("dap")
local dap_view = require("dap-view")
local keymaps = require("util.keymaps")
local map = vim.keymap.set

dap_view.setup()

vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DiagnosticHint", linehl = "", numhl = "" })
vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "→", texthl = "DiagnosticOk", linehl = "DapStoppedLine", numhl = "" })

-- Toggle debug UI
map("n", keymaps.toggle("D"), function()
  dap_view.toggle()
end, { desc = "Toggle Debug UI" })

-- Debug keymaps
map("n", keymaps.debug("c"), dap.continue, { desc = "Continue" })
map("n", keymaps.debug("b"), dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
map("n", keymaps.debug("B"), function()
  dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Conditional Breakpoint" })
map("n", keymaps.debug("o"), dap.step_over, { desc = "Step Over" })
map("n", keymaps.debug("i"), dap.step_into, { desc = "Step Into" })
map("n", keymaps.debug("O"), dap.step_out, { desc = "Step Out" })
map("n", keymaps.debug("r"), dap.restart, { desc = "Restart" })
map("n", keymaps.debug("t"), dap.terminate, { desc = "Terminate" })
map("n", keymaps.debug("l"), dap.run_last, { desc = "Run Last" })

-- Open/close dap-view on debug session events
dap.listeners.before.attach["dap-view-config"] = function()
  dap_view.open()
end
dap.listeners.before.launch["dap-view-config"] = function()
  dap_view.open()
end
dap.listeners.before.event_terminated["dap-view-config"] = function()
  dap_view.close()
end
dap.listeners.before.event_exited["dap-view-config"] = function()
  dap_view.close()
end
