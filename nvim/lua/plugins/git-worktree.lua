return {
    'ThePrimeagen/git-worktree.nvim',
    config = function()
        local worktree = require('git-worktree')

        require('telescope').load_extension('git_worktree')

        worktree.setup()
    end
}
