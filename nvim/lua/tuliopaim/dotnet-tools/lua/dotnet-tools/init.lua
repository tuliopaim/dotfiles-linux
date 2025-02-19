local secrets = require('dotnet-tools.secrets')
local open_in_rider = require('dotnet-tools.open-in-rider')
local tests = require('dotnet-tools.tests')

local M = {}

M.open_or_create_secrets_file = secrets.open_or_create_secrets_file

M.setup = function(opts)
    vim.api.nvim_create_user_command('UserSecrets', secrets.open_or_create_secrets_file, {})
    vim.api.nvim_create_user_command('OpenInRider', function() open_in_rider.open_in_rider(opts) end, {})
    vim.api.nvim_create_user_command('Test', tests.run_test_at_cursor, {})
    vim.api.nvim_create_user_command('TestClass', tests.run_test_class, {})
end

return M
