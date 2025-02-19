return {
    {
        'tpope/vim-fugitive'
    },
    {
		"lewis6991/gitsigns.nvim",
		event = "VeryLazy",
		config = function()
			require("gitsigns").setup()

            vim.keymap.set("n", "<leader>gb", ":Gitsigns toggle_current_line_blame<cr>")
		end,
	},
    {
		"sindrets/diffview.nvim",
		event = "VeryLazy"
	},
}
