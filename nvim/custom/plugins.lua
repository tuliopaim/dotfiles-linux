local overrides = require("custom.configs.overrides")

---@type NvPluginSpec[]
local plugins = {

    -- Install a plugin
    {
        "max397574/better-escape.nvim",
        event = "InsertEnter",
        config = function()
            require("better_escape").setup()
        end,
    },

    {
        "williamboman/mason.nvim",
        opts = {
            ensure_installed = {
                "lua-language-server",
                "html-lsp",
                "prettier",
                "stylua",
                "omnisharp"
            },
        },
    }

    -- To make a plugin not be loaded
    -- {
    --   "NvChad/nvim-colorizer.lua",
    --   enabled = false
    -- },

}

return plugins
