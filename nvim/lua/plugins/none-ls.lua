return {
    "nvimtools/none-ls.nvim",
    config = function()
        require("null-ls").setup()

        local null_ls = require("null-ls")

        null_ls.setup({
            border = "rounded",
            sources = {
                null_ls.builtins.formatting.stylua,
                null_ls.builtins.formatting.csharpier,
            },
        })

        vim.keymap.set('n', '<leader>gf', vim.lsp.buf.format, {})

    end,
}
