return {
    {
        "nvim-telescope/telescope-ui-select.nvim",
    },
    {
        'nvim-telescope/telescope.nvim',
        tag = "0.1.5",
        dependencies = {
            {'nvim-lua/plenary.nvim'},
            {'folke/trouble.nvim'},
            {'ThePrimeagen/git-worktree.nvim'}
        },
        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")

            vim.api.nvim_create_autocmd("FileType", {
                pattern = "TelescopeResults",
                callback = function(ctx)
                    vim.api.nvim_buf_call(ctx.buf, function()
                        vim.fn.matchadd("TelescopeParent", "\t\t.*$")
                        vim.api.nvim_set_hl(0, "TelescopeParent", { link = "Comment" })
                    end)
                end,
            })

            local picker_opts = {
                layout_strategy='vertical',
                fname_width = 120,
            }

            telescope.setup {
                defaults = {
                    mappings = {
                        i = {
                            ["<c-t>"] = require("trouble.sources.telescope").open,
                            ['<c-d>'] = actions.delete_buffer
                        },
                        n = {
                            ["<c-t>"] = require("trouble.sources.telescope").open,
                            ['<c-d>'] = actions.delete_buffer
                        },
                    },
                },
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown()
                    }
                },
                pickers = {
                    find_files = picker_opts,
                    lsp_definitions = picker_opts,
                    lsp_references = picker_opts,
                    lsp_implementations = picker_opts,
                    diagnostics = picker_opts,
                    git_files = picker_opts,
                    live_grep = picker_opts,
                    grep_string = picker_opts,
                }
            }

            telescope.load_extension("ui-select")

            local builtin = require('telescope.builtin')

            -- find files

            vim.keymap.set('n', '<leader>ff', function()
                builtin.find_files(
                {
                    layout_strategy='vertical',
                    hidden= true
                })
            end);
            vim.keymap.set('n', '<C-p>', builtin.git_files, {})

            -- search word
            vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = "[?] [S]earch [H]elp" })
            vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
            vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
            vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
            vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
            vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
            vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
            vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

            vim.keymap.set('n', '<leader>fws', function()
                local word = vim.fn.expand("<cword>")
                builtin.grep_string({ search = word })
            end)

            vim.keymap.set('n', '<leader>fWs', function()
                local word = vim.fn.expand("<cWORD>")
                builtin.grep_string({ search = word })
            end)

            vim.keymap.set('n', '<leader>/', function()
                -- You can pass additional configuration to telescope to change theme, layout, etc.
                builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                    winblend = 10,
                    previewer = false,
                })
            end, { desc = '[/] Fuzzily search in current buffer' })

            -- worktree
            vim.keymap.set('n', '<leader>gwt', function()
                telescope.extensions.git_worktree.git_worktrees()
            end)

            vim.keymap.set('n', '<leader>gwT', function()
                telescope.extensions.git_worktree.create_git_worktree()
            end)

            -- Shortcut for searching your neovim configuration files
            vim.keymap.set('n', '<leader>sn', function()
                builtin.find_files { cwd = vim.fn.stdpath 'config' }
            end, { desc = '[S]earch [N]eovim files' })
       end
    }
}
