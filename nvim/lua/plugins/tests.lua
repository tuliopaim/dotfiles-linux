return {
    "nvim-neotest/neotest",
    dependencies = {
        "Issafalcon/neotest-dotnet",
        "nvim-neotest/nvim-nio",
        "nvim-lua/plenary.nvim",
        "antoinemadec/FixCursorHold.nvim",
        "nvim-treesitter/nvim-treesitter"
    },
    event = "VeryLazy",
    config = function()
        require("neotest").setup({
            adapters = {
                require("neotest-dotnet")
            }
        })

        local neotest = require("neotest")

        vim.api.nvim_create_user_command('TestDebug', function() neotest.run.run({strategy = "dap"}) end, {})
    end,
}
