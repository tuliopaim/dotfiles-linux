return {
    "ThePrimeagen/harpoon",
    dependencies = {"nvim-lua/plenary.nvim"},
    config = function()
        require("harpoon").setup({
            menu = {
                width = 120
            }
        })
        vim.keymap.set('n', "<leader>hi", function() require('harpoon.mark').add_file() end)
        vim.keymap.set('n', "<leader>hh", function() require('harpoon.ui').toggle_quick_menu() end)
        vim.keymap.set('n', "<leader>1", function() require('harpoon.ui').nav_file(1)end)
        vim.keymap.set('n', "<leader>2", function() require('harpoon.ui').nav_file(2)end)
        vim.keymap.set('n', "<leader>3", function() require('harpoon.ui').nav_file(3)end)
        vim.keymap.set('n', "<leader>4", function() require('harpoon.ui').nav_file(4)end)
        vim.keymap.set('n', "<leader>5", function() require('harpoon.ui').nav_file(5)end)
        vim.keymap.set('n', "<leader>gk", function() require('harpoon.ui').nav_next()end)
        vim.keymap.set('n', "<leader>gj", function() require('harpoon.ui').nav_prev()end)
    end
}
