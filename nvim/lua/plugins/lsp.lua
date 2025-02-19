local on_attach = function(client, bufnr)
    local telescope_builtin = require("telescope.builtin")

    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {buffer = bufnr, desc = "[G]oto [I]mplementation"})

    vim.keymap.set("n", 'gd', telescope_builtin.lsp_definitions, {buffer = bufnr, desc = '[G]oto [D]efinition' })
    vim.keymap.set("n", "gr", telescope_builtin.lsp_references, {buffer = bufnr, desc = "LSP: [G]oto [R]eferences" })
    vim.keymap.set("n", "gi", telescope_builtin.lsp_implementations, {buffer = bufnr, desc = "[G]o to [I]mplementations"})
    vim.keymap.set("n", '<leader>D', telescope_builtin.lsp_type_definitions, {buffer = bufnr, desc = 'Type [D]efinition'})
    vim.keymap.set("n", "<leader>ds", telescope_builtin.lsp_document_symbols, {buffer = bufnr, desc = "[D]ocument [S]ymbols"})
    vim.keymap.set("n", "<leader>ws", telescope_builtin.lsp_dynamic_workspace_symbols, {buffer = bufnr, desc = "[W]orkspace [S]ymbols"})

    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {buffer = bufnr, desc = "[R]e[n]ame"})
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {buffer = bufnr, desc = "[C]ode [A]ction"})

    vim.keymap.set("n", "K", vim.lsp.buf.hover, {buffer = bufnr, desc = "Hover Documentation"})
    vim.keymap.set("n", "<leader>k", vim.diagnostic.open_float, {buffer = bufnr, desc = "Float Documentation"})
    vim.keymap.set("n", "<leader>K", vim.lsp.buf.signature_help, {buffer = bufnr, desc = "Signature Help"})

    vim.keymap.set("i", "<c-k>", vim.lsp.buf.signature_help, {buffer = bufnr, desc = "Signature Help"})
end

return {

    {
        "seblj/roslyn.nvim",
        ft = "cs",
        opts = {
            exe = { "Microsoft.CodeAnalysis.LanguageServer" },
            config = {
                on_attach = on_attach,
                handlers = {
                    ["textDocument/hover"] = function(err, result, ctx, config)
                        if result and result.contents and result.contents.value then
                            result.contents.value = result.contents.value:gsub("\\([^%w])", "%1")
                        end
                        vim.lsp.handlers["textDocument/hover"](err, result, ctx, config)
                    end,
                },
            },
        }
    },

    { "williamboman/mason.nvim", config = true },

    {
        "williamboman/mason-lspconfig.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "neovim/nvim-lspconfig",
			"hrsh7th/cmp-nvim-lsp",
            "folke/neodev.nvim",
            "Decodetalkers/csharpls-extended-lsp.nvim",
        },
        config = function()
            vim.diagnostic.config({
                virtual_text = true,
                severity_sort = true,
                float = {
                    style = 'minimal',
                    border = 'rounded',
                    source = 'always',
                    header = '',
                    prefix = '',
                },
            })

            local cmp_nvim_lsp = require("cmp_nvim_lsp")
            local capabilities = vim.tbl_deep_extend(
                "force",
                vim.lsp.protocol.make_client_capabilities(),
                cmp_nvim_lsp.default_capabilities()
            )

            require("mason-lspconfig").setup({
                ensure_installed = { "cssls", "docker_compose_language_service", "dockerls", "eslint", "rnix", "ts_ls" }
            })

            require('lspconfig').lua_ls.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                    Lua = {
                        format = { enable = false },
                        telemetry = { enable = false },
                        workspace = { checkThirdParty = false },
                        diagnostics = { globals = { "vim" } }
                    },
                },
            })

            require('lspconfig').gopls.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                    gopls = {
                        staticcheck = true,
                        gofumpt = false,
                    },
                },
            })


            require("mason-lspconfig").setup_handlers({

                function(server_name)
                    require("lspconfig")[server_name].setup({
                        on_attach = on_attach,
                        capabilities = capabilities,
                    })
                end,

                ["lua_ls"] = function()
                    require("neodev").setup()
                    require("lspconfig").lua_ls.setup({
                        on_attach = on_attach,
                        capabilities = capabilities,
                        settings = {
                            Lua = {
                                format = { enable = false },
                                telemetry = { enable = false },
                                workspace = { checkThirdParty = false },
                            },
                        },
                    })
                end,

                ["csharp_ls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.csharp_ls.setup({
                        handlers = {
                            ["textDocument/definition"] = require('csharpls_extended').handler,
                            ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" }),
                            ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" }),
                        },

                        root_dir = function(startpath)
                            return lspconfig.util.root_pattern("*.sln")(startpath)
                                or lspconfig.util.root_pattern("*.csproj")(startpath)
                                or lspconfig.util.root_pattern("*.fsproj")(startpath)
                                or lspconfig.util.root_pattern(".git")(startpath)
                        end,

                        on_attach = on_attach,
						capabilities = capabilities,
                    })
                end,

			})

            -- Configure borderd for LspInfo ui
			require("lspconfig.ui.windows").default_options.border = "rounded"
		end,
	}
}
