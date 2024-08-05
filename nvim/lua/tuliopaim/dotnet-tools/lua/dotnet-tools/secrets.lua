local function find_user_secrets_id(path)
    local files = vim.fn.glob(path .. "*.csproj", false, true)

    for _, file in ipairs(files) do
        local f = io.open(file, "r")
        if f then
            local content = f:read("*all")
            f:close()
            for secrets_id in string.gmatch(content, "<UserSecretsId>(.-)</UserSecretsId>") do
                return secrets_id
            end
        end
    end

    return nil
end

local M = {}

M.open_or_create_secrets_file = function ()
    local current_dir = vim.fn.expand('%:p:h') .. "/"

    local secrets_id = find_user_secrets_id(current_dir)
    local dotnet_user_secrets_cmd = 'dotnet user-secrets -p ' .. current_dir

    if not secrets_id then
        print("No secrets found, initiating dotnet user-secrets...")
        print(vim.fn.system(dotnet_user_secrets_cmd .. ' init'))
        secrets_id = find_user_secrets_id(current_dir)
        print("Secret initialized... " .. secrets_id)
    end

    if not secrets_id then
        print("Secret not created, shutting down...")
        return
    end

    local file_path = vim.fn.expand("$HOME") .. "/.microsoft/usersecrets/" .. secrets_id .. "/secrets.json"

    if vim.fn.filereadable(file_path) == 1 then
        print("secrets.json found, opening...")
        vim.cmd("edit " .. file_path)
        return
    end

    print("secrets.json not found, creating with default values...")

    print(vim.fn.system(dotnet_user_secrets_cmd .. ' set "foo" "bar"'))

    if vim.fn.filereadable(file_path) == 1 then
        vim.cmd("edit " .. file_path)
        return
    end

    print("Failed to create secrets.json file, shutting down...")
end

return M
