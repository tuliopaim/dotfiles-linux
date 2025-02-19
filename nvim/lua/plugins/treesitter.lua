return {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    tag = 'v0.9.1',
    config = function()
        local config = require("nvim-treesitter.configs")
        config.setup({
            ensure_installed = {
                	"bash",
					"c",
					"css",
					"gleam",
					"graphql",
					"html",
					"javascript",
					"json",
					"lua",
					"markdown",
					"ocaml",
					"ocaml_interface",
					"prisma",
					"tsx",
					"typescript",
					"vim"
            },
            auto_install = true,
            highlight = { enable = true },
            indent = { enable = true },
            text_objects = {
                select = {
                    enable = true,
                    lookahead = true,
                    keymaps = {
                        ["af"] = "@function.outer",
                        ["if"] = "@function.inner",
                        ["ac"] = "@class.outer",
                        ["ic"] = "@class.inner",
                    },
                },
            },
        })
    end
}

