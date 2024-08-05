return {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    priority = 1000,
    config = function()
        require("catppuccin").setup({
            flavour = "mocha", -- latte, frappe, macchiato, mocha
            integrations = {
                cmp = true,
                gitsigns = true,
                harpoon = true,
                illuminate = true,
                indent_blankline = {
                    enabled = false,
                    scope_color = "sapphire",
                    colored_indent_levels = false,
                },
                mason = true,
                native_lsp = { enabled = true },
                notify = true,
                nvimtree = true,
                neotree = true,
                symbols_outline = true,
                telescope = true,
                treesitter = true,
                treesitter_context = true,
            },
            transparent_background = true,
        })

        vim.cmd.colorscheme "catppuccin"
    end
}
