local M = {}


M.open_in_rider = function(opts)
    local script_path = 'rider'

    if opts ~= nil and opts.script_path ~= nil then
        script_path = opts.script_path
    end

    local path = vim.fn.expand('%:p')
    local line = vim.fn.line('.')
    local cmd = string.format('%s --line %d %s', script_path, line, path)

    print('Opening in Rider: ' .. script_path .. ' ' ..cmd)

    -- Run the command asynchronously in the background
    local job_id = vim.fn.jobstart(cmd, {
        on_exit = function(_, code, _)
            if code ~= 0 then
                print("Error: Rider command failed with exit code " .. code)
            end
        end
    })

    -- Check if the job was started successfully
    if job_id <= 0 then
        print("Error: Failed to start Rider command")
    end
end

return M
