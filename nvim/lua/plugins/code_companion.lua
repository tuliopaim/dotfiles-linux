return {
    "olimorris/codecompanion.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    config = function()
        require("codecompanion").setup({
            strategies = {
                chat = {
                    adapter = "anthropic",
                },
                inline = {
                    adapter = "anthropic",
                    keymaps = {
                        accept_change = {
                            modes = { n = "ga" },
                            description = "Accept the suggested change",
                        },
                        reject_change = {
                            modes = { n = "gr" },
                            description = "Reject the suggested change",
                        },
                    },
                },
                cmd = {
                    adapter = "gemini"
                }
            },
            display = {
                chat = {
                    auto_scroll = false,
                }
            }
        })

        vim.keymap.set({ "n", "v" }, "<leader>cc", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
        vim.keymap.set({ "n", "v" }, "<leader>aa", ":CodeCompanionChat Toggle<CR>",
            { noremap = true, silent = true, desc = "Trigger Code Companion" })
        vim.keymap.set("v", "ga", ":CodeCompanionChat Add<CR>",
            { noremap = true, silent = true, desc = "Add to chat context" })
    end,
}
