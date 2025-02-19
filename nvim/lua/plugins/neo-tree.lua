return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
        { "<leader>e", ":Neotree toggle<CR>", desc = "Toggle neotree" },
        { "<leader>.", ":Neotree focus<CR>", desc = "Toggle neotree" },
        { "<leader>sb", ":Neotree buffers reveal float<CR>", desc = "Reveal buffers" },
        { "<leader>ha", ":Neotree close<CR>", desc = "Toggle neotree" },
    },
    config = function()
        require('neo-tree').setup({
            close_if_last_window = false,
            popup_border_style = "rounded",
            enable_git_status = true,
            enable_diagnostics = true,
            enable_normal_mode_for_inputs = false,
            open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
            sort_case_insensitive = false,
            sort_function = nil,
            filesystem = {
                filtered_items = {
                    visible = false, -- when true, they will just be displayed differently than normal items
                    hide_dotfiles = false,
                    hide_gitignored = false,
                    hide_hidden = false, -- only works on Windows for hidden files/directories
                },
            },
            follow_current_file = {
                enabled = true, -- This will find and focus the file in the active buffer every time
                leave_dirs_open = true, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
            },
    })
    end
}
