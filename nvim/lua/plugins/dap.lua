return {
	{
		"mfussenegger/nvim-dap",
        lazy = true,
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "theHamsta/nvim-dap-virtual-text",
            "nvim-neotest/nvim-nio",
            "williamboman/mason.nvim"
        },
        config = function()
            local dap = require("dap")
            local dap_utils = require("dap.utils")
            local dotnet_helper = require("dotnet-tools.helpers")
            local ui = require("dapui")

            require("dapui").setup()

            local config = {
                {
                    type = "coreclr",
                    name = "Launch Console in Development",
                    request = "launch",
                    program = function()

                        if vim.fn.confirm('Should I recompile first?', '&yes\n&no', 2) == 1 then
                            dotnet_helper.build_project()
                        end

                        return dotnet_helper.get_dll_path()
                    end,
                    env = {
                        DOTNET_ENVIRONMENT = "Development"
                    }
                },
                {
                    type = "coreclr",
                    name = "Launch WEB in Development",
                    request = "launch",
                    program = function()
                        if vim.fn.confirm('Should I recompile first?', '&yes\n&no', 2) == 1 then
                            vim.g.dotnet_build_project()
                        end

                        return dotnet_helper.get_dll_path()
                    end,
                    env = {
                        ASPNETCORE_ENVIRONMENT = "Development"
                    }
                },
                {
                    type = "coreclr",
                    name = "Attach",
                    request = "attach",
                    processId = dap_utils.pick_process,
                },

                {
                    type = "coreclr",
                    name = "Attach (Smart)",
                    request = "attach",
                    processId = function()
                        local current_working_dir = vim.fn.getcwd()
                        return dotnet_helper.dap_smart_pick_process(dap_utils, current_working_dir) or dap.ABORT
                    end,
                },
            }

            dap.configurations.cs = config
            dap.configurations.fsharp = config

            dap.adapters.netcoredbg = {
                type = 'executable',
                command = 'netcoredbg',
                args = {
                    '--interpreter=vscode',
                }
            }

            dap.adapters.coreclr = {
                type = 'executable',
                command = 'netcoredbg',
                args = {
                    '--interpreter=vscode',
                }
            }

            vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "DAP: Toggle breakpoint" })
            vim.keymap.set("n", "<s-F9>", function()
                local condition = vim.fn.input("Breakpoint Condition: ")
                if condition then
                    dap.set_breakpoint(condition)
                end
                end, { desc = "DAP: Set conditional breakpoint" })

            vim.keymap.set("n", "<F5>", dap.continue)
            vim.keymap.set("n", "<F10>", dap.step_over)
            vim.keymap.set("n", "<F11>", dap.step_into)
            vim.keymap.set("n", "<F7>", dap.step_out)
            vim.keymap.set("n", "<F6>", dap.step_back)
            vim.keymap.set("n", "<F2>", dap.restart)
            vim.keymap.set("n", "<F4>", "<cmd>lua require'dap'.disconnect({ terminateDebuggee = true })<CR><cmd>lua require'dap'.close()<CR>")

            vim.keymap.set("n", "<leader>de", function()
                local expr = vim.fn.input("Evaluate Expression: ")
                if expr then
                    require("dapui").eval(expr)
                end
            end, { desc = "DAP: Evaluate expression" })

            -- Eval var under cursor
            vim.keymap.set("n", "<space>?", function()
                require("dapui").eval(nil, { enter = true })
            end)

            dap.listeners.before.attach.dapui_config = function()
                ui.open()
            end
            dap.listeners.before.launch.dapui_config = function()
                ui.open()
            end
            dap.listeners.before.event_terminated.dapui_config = function()
                ui.close()
            end
            dap.listeners.before.event_exited.dapui_config = function()
                ui.close()
            end
		end,
	},
}
