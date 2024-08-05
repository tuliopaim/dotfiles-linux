local helpers = require('dotnet-tools.helpers')

local run_test_and_print = function(testCmd)
    -- Check if in a tmux session
    local tmux_session = os.getenv("TMUX")

    if tmux_session then
        -- In a tmux session, open a new tmux pane at the bottom and run the command
        os.execute('tmux split-window -v "sh -c \'' .. testCmd .. '; exec zsh\'"')
    else
        -- Not in a tmux session, open a new split window in Neovim
        vim.cmd('botright split')
        vim.cmd('terminal ' .. testCmd)
        vim.cmd('startinsert!')
    end
end

local M = {}

M.run_test_at_cursor = function()
    local class_name = helpers.get_class_name()
    local test_name = helpers.get_function_name_with_treesitter()

    if not test_name then
        print ('No test name found')
        return
    end

    local cmd = string.format('dotnet test --filter "%s.%s"', class_name, test_name)

    run_test_and_print(cmd)
end

M.run_test_class = function()
    local class_name = helpers.get_class_name()

    local cmd = string.format("dotnet test --filter FullyQualifiedName~%s", class_name)

    run_test_and_print(cmd)
end

return M
