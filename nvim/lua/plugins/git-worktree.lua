return {
    'ThePrimeagen/git-worktree.nvim',
    lazy = true,
    config = function()
        local worktree = require('git-worktree')

        require('telescope').load_extension('git_worktree')

        worktree.setup()
    end
}
