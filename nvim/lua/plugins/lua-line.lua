return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons'},
    config = function()
        vim.keymap.set("n", "<leader>lr", ":LualineRenameTab ")

		local lualine = require("lualine")

		local conditions = {
			buffer_not_empty = function()
				return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
			end,
			hide_in_width = function()
				return vim.fn.winwidth(0) > 80
			end,
			check_git_workspace = function()
				local filepath = vim.fn.expand("%:p:h")
				local gitdir = vim.fn.finddir(".git", filepath .. ";")
				return gitdir and #gitdir > 0 and #gitdir < #filepath
			end,
		}

		local filename = {
			"filename",
			cond = conditions.buffer_not_empty,
			path = 1,
			-- padding = { left = 1, right = 0 },
		}

		local mode = {
			"mode",
		}

		local location = {
			"location",
		}

		local branch = {
			"branch",
		}

		local diagnostics_circle = "●";

		local diagnostics = {
			"diagnostics",
			sources = { "nvim_diagnostic" },
			update_in_insert = true,
			sections = { "error", "warn", "info" },
			symbols = {
				error = diagnostics_circle .. " ",
				warn = diagnostics_circle .. " ",
				info = diagnostics_circle .. " ",
			},
			-- symbols = { error = " ", warn = " ", info = " " },
			-- symbols = { error = " ", warn = " ", info = " " },
			-- symbols = { error = " ", warn = " ", info = " " },
			-- diagnostics_color = {
			-- 	color_error = "DiagnosticSignError",
			-- 	color_warn = "DiagnosticSignWarn",
			-- 	color_info = "DiagnosticSignInfo",
			-- },
		}

		lualine.setup({
			options = {
				icons_enabled = true,
				theme = "catppuccin",
                component_separators = { left = "", right = "" },
                section_separators = { left = "█", right = "█" },
				disabled_filetypes = {
					statusline = {},
					winbar = { "NvimTree" },
				},
				ignore_focus = {},
				always_divide_middle = true,
				globalstatus = true,
				refresh = {
					statusline = 1000,
					tabline = 1000,
					winbar = 1000,
				},
			},
			sections = {
				lualine_a = { mode },
				lualine_b = { branch, "diff", diagnostics },
				lualine_c = { filename },
				lualine_x = { "filetype" },
				lualine_y = { },
				lualine_z = { location },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = {},
				lualine_x = {},
				lualine_y = {},
				lualine_z = {},
			},
			winbar = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = {},
				lualine_x = {},
				lualine_y = {},
				lualine_z = {},
			},
			inactive_winbar = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = {},
				lualine_x = {},
				lualine_y = {},
				lualine_z = {},
			},
			-- tabline = {
			-- 	lualine_a = {},
			-- 	lualine_b = { tabs },
			-- 	lualine_c = {},
			-- 	lualine_x = {},
			-- 	lualine_y = {},
			-- 	lualine_z = {},
			-- },
			extensions = { "fugitive", "quickfix" },
		})
    end
}

