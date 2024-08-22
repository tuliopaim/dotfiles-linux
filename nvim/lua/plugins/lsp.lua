local on_attach = function(client, bufnr)

    local map = function(keys, func, desc)
        if desc then
            desc = "LSP: " .. desc
        end

        vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
    end

    local imap = function(keys, func, desc)
        if desc then
            desc = "LSP: " .. desc
        end

        vim.keymap.set("i", keys, func, { buffer = bufnr, desc = desc })
    end

    map("gi", vim.lsp.buf.implementation, "[G]oto [I]mplementation")

    local telescope_builtin = require("telescope.builtin")

    map('gd', telescope_builtin.lsp_definitions, '[G]oto [D]efinition')
    map("gr", telescope_builtin.lsp_references, "LSP: [G]oto [R]eferences" )
    map("gi", telescope_builtin.lsp_implementations, "[G]o to [I]mplementations")
    map('<leader>D', telescope_builtin.lsp_type_definitions, 'Type [D]efinition')
    map("<leader>ds", telescope_builtin.lsp_document_symbols, "[D]ocument [S]ymbols")
    map("<leader>ws", telescope_builtin.lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

    map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

    map("K", vim.lsp.buf.hover, "Hover Documentation")
    map("<leader>k", vim.diagnostic.open_float, "Float Documentation")
    map("<leader>K", vim.lsp.buf.signature_help, "Signature Help")
    imap("<c-k>", vim.lsp.buf.signature_help, "Signature Help")
end

return {

    { "williamboman/mason.nvim", config = true },

    {
        "williamboman/mason-lspconfig.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "neovim/nvim-lspconfig",
			"hrsh7th/cmp-nvim-lsp",
            "folke/neodev.nvim",
            "seblj/roslyn.nvim",
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

            -- DOTNET LSP
            require("roslyn").setup({
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
            })

            require("mason-lspconfig").setup({
                ensure_installed = { "cssls", "docker_compose_language_service", "dockerls", "eslint", "rnix", "tsserver" }
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

				["gopls"] = function()
					require("lspconfig").gopls.setup({
						on_attach = on_attach,
						capabilities = capabilities,
						settings = {
							gopls = {
								staticcheck = true,
								gofumpt = false,
							},
						},
					})
				end,

			})

            -- Configure borderd for LspInfo ui
			require("lspconfig.ui.windows").default_options.border = "rounded"
		end,
	}
}
