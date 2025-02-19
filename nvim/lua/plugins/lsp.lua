local on_attach = function(_, bufnr)
    vim.keymap.set("n", 'gd', function() Snacks.picker.lsp_definitions() end, { buffer = bufnr, desc = '[G]oto [D]efinition' })
    vim.keymap.set("n", "gr", function() Snacks.picker.lsp_references() end, { buffer = bufnr, desc = "LSP: [G]oto [R]eferences" })
    vim.keymap.set("n", "gi", function() Snacks.picker.lsp_implementations() end, { buffer = bufnr, desc = "[G]o to [I]mplementations" })
    vim.keymap.set("n", "<leader>ds", function() Snacks.picker.lsp_symbols() end, { buffer = bufnr, desc = "[D]ocument [S]ymbols" })
    vim.keymap.set("n", "<leader>ws", function() Snacks.picker.lsp_workspace_symbols() end, { buffer = bufnr, desc = "[W]orkspace [S]ymbols" })

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
            "folke/neodev.nvim",
            "Decodetalkers/csharpls-extended-lsp.nvim",
            "folke/snacks.nvim"
        },
        config = function()
            vim.diagnostic.config({
                virtual_text = true,
                severity_sort = true,
                float = {
                    style = 'minimal',
                    border = 'rounded',
                    header = '',
                    prefix = '',
                },
            })

            local capabilities = vim.tbl_deep_extend(
                "force",
                vim.lsp.protocol.make_client_capabilities(),
                require('blink-cmp').get_lsp_capabilities()
            )

            require("mason-lspconfig").setup {
                ensure_installed = {
                    "cssls",
                    "docker_compose_language_service",
                    "dockerls",
                    "eslint",
                    "rnix",
                    "ts_ls",
                    "pylsp"
                },
                automatic_installation = true
            }

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

            require("lspconfig").nixd.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                cmd = { "nixd" },
                settings = {
                    nixd = {
                        nixpkgs = {
                            expr = "import <nixpkgs> { }",
                        },
                        formatting = {
                            command = { "nixpkgs-fmt"},
                        }
                    },
                    options = {
                        nixos = {
                            expr = '(builtins.getFlake "/home/tuliopaim/dotfiles/nix).nixosConfigurations.nixos.options'
                        },
                        home_manager = {
                            expr = '(builtins.getFlake "/home/tuliopaim/dotfiles/nix).homeManagerConfigurations.tuliopaim.options'
                        }
                    }
                }
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

            require('lspconfig').pylsp.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                    pylsp = {
                        pyflakes = { enabled = false },
                        pycodestayle = { enabled = false },
                        autopep8 = { enabled = false },
                        yapf = { enabled = false },
                        mccabe = { enabled = false },
                        pylsp_mypy = { enabled = false },
                        pylsp_black = { enabled = false },
                        pylsp_isort = { enabled = false },
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

						--           ["csharp_ls"] = function()
						--               local lspconfig = require("lspconfig")
						--               lspconfig.csharp_ls.setup({
						--                   handlers = {
						--                       ["textDocument/definition"] = require('csharpls_extended').handler,
						--                       ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" }),
						--                       ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" }),
						--                   },
						--
						--                   root_dir = function(startpath)
						--                       return lspconfig.util.root_pattern("*.sln")(startpath)
						--                           or lspconfig.util.root_pattern("*.csproj")(startpath)
						--                           or lspconfig.util.root_pattern("*.fsproj")(startpath)
						--                           or lspconfig.util.root_pattern(".git")(startpath)
						--                   end,
						--
						--                   on_attach = on_attach,
						-- capabilities = capabilities,
						--               })
						--           end,

			})

            -- Configure borderd for LspInfo ui
			require("lspconfig.ui.windows").default_options.border = "rounded"
		end,
	}
}
