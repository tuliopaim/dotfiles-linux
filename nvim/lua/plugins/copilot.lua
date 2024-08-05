return {
    {
		"zbirenbaum/copilot.lua",
        command = "Copilot",
		event = { "BufEnter", "InsertEnter" },
		config = function()
			require("copilot").setup({
                enabled = true,
                auto_refresh = true,
				suggestion = {
					enabled = true,
                    auto_trigger = true,
                    keymap = {
                        accept = "<c-y>",
                        next = "<right>",
                        prev = "<left>",
                        dismiss = "<CR>",
                    }
				},
				panel = { enabled = false },
			})
		end,
	}
}
