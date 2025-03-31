vim.g.mapleader = ' '
vim.keymap.set("n", "<leader>ntw", vim.cmd.Ex)

local opts = { noremap = true, silent = true }

--Remap space as leader key
vim.api.nvim_set_keymap("", "<Space>", "<Nop>", opts)

vim.cmd("command W w")
vim.cmd("command Q q")
vim.cmd("command Qa qa")

-- Normal --
-- Better window navigation
--vim.api.nvim_set_keymap('n', "<C-d>", "<C-d>zz", opts)
--vim.api.nvim_set_keymap('n', "<C-u>", "<C-u>zz", opts)
vim.api.nvim_set_keymap('n', "<leader>v", ":vsplit<CR>", opts)
vim.api.nvim_set_keymap('n', "<leader>b", ":split<CR>", opts)

vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-- Tabs
vim.api.nvim_set_keymap("n", "<leader>rk", ":resize +5<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>rj", ":resize -5<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>rh", ":vertical resize -5<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>rl", ":vertical resize +5<CR>", opts)

vim.api.nvim_set_keymap("n", "<leader>tN", ":tabnew<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>tp", ":tabprevious<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>tn", ":tabnext<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>tc", ":tabclose<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>ts", ":tab split<CR>", opts)

vim.api.nvim_set_keymap("n", "gj", ":bp<CR>", opts)
vim.api.nvim_set_keymap("n", "gk", ":bn<CR>", opts)

vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Center buffer while navigating
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "{", "{zz")
vim.keymap.set("n", "}", "}zz")
vim.keymap.set("n", "N", "Nzz")
vim.keymap.set("n", "n", "nzz")
vim.keymap.set("n", "G", "Gzz")
vim.keymap.set("n", "gg", "ggzz")
vim.keymap.set("n", "<C-i>", "<C-i>zz")
vim.keymap.set("n", "<C-o>", "<C-o>zz")
vim.keymap.set("n", "%", "%zz")
vim.keymap.set("n", "*", "*zz")
vim.keymap.set("n", "#", "#zz")

-- greatest remap ever
vim.keymap.set({ "n", "v" }, "<leader>p", "\"0p")
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- Press '<leader>fr' for quick find/replace for the word under the cursor
vim.keymap.set("n", "<leader>fr", function()
    local cmd = ":%s/<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>"
    local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
    vim.api.nvim_feedkeys(keys, "n", false)
end)

-- Goto next diagnostic of any severity
vim.keymap.set("n", "]d", function()
    vim.diagnostic.goto_next({})
    vim.api.nvim_feedkeys("zz", "n", false)
end)

-- Goto previous diagnostic of any severity
vim.keymap.set("n", "[d", function()
    vim.diagnostic.goto_prev({})
    vim.api.nvim_feedkeys("zz", "n", false)
end)

-- Goto next error diagnostic
vim.keymap.set("n", "]e", function()
    vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
    vim.api.nvim_feedkeys("zz", "n", false)
end)

-- Goto previous error diagnostic
vim.keymap.set("n", "[e", function()
    vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
    vim.api.nvim_feedkeys("zz", "n", false)
end)

-- Goto next warning diagnostic
vim.keymap.set("n", "]w", function()
    vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN })
    vim.api.nvim_feedkeys("zz", "n", false)
end)

-- Goto previous warning diagnostic
vim.keymap.set("n", "[w", function()
    vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN })
    vim.api.nvim_feedkeys("zz", "n", false)
end)

-- Place all dignostics into a qflist
vim.keymap.set("n", "<leader>ld", vim.diagnostic.setqflist, { desc = "Quickfix [L]ist [D]iagnostics" })

-- Turn off highlighted results
vim.keymap.set("n", "<leader>no", "<cmd>noh<cr>")

vim.keymap.set("n", "<leader>oc", function()
    require("copilot.panel").open({})
end, { desc = "[O]pen [C]opilot panel" })

-- Create TODO command to open daily notes in a float window
vim.api.nvim_create_user_command("TODO", function()
    -- Expand the home directory path
    local file_path = vim.fn.expand("~/vault/DAILY NOTES.md")

    -- Calculate window size (% of editor size)
    local width = math.floor(vim.api.nvim_get_option("columns") * 0.5)
    local height = math.floor(vim.api.nvim_get_option("lines") * 0.5)

    -- Calculate starting position to center the window
    local row = 0
    local col = math.floor((vim.api.nvim_get_option("columns") - width))

    -- Create the floating window
    local buf = vim.api.nvim_create_buf(false, true)
    local win_opts = {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    }

    local win = vim.api.nvim_open_win(buf, true, win_opts)

    -- Set some window options
    vim.api.nvim_win_set_option(win, "winblend", 0)
    vim.api.nvim_win_set_option(win, "wrap", true)

    -- Try to read the file into the buffer
    vim.api.nvim_command("edit " .. file_path)
end, {})

-- Avante
vim.api.nvim_create_user_command('AvanteReset', function()
    vim.cmd('AvanteClear')
    vim.cmd('AvanteRefresh')
end, {})
