local M = {}

M.dotnet_build_project = function()
    local default_path = vim.fn.getcwd() .. '/'
    if vim.g['dotnet_last_proj_path'] ~= nil then
        default_path = vim.g['dotnet_last_proj_path']
    end
    local path = vim.fn.input('Path to your *proj file', default_path, 'file')
    vim.g['dotnet_last_proj_path'] = path
    local cmd = 'dotnet build -c Debug ' .. path .. ' > /dev/null'
    print('')
    print('Cmd to execute: ' .. cmd)
    local f = os.execute(cmd)
    if f == 0 then
        print('\nBuild: ✔️ ')
    else
        print('\nBuild: ❌ (code: ' .. f .. ')')
    end
end

vim.api.nvim_set_keymap('n', '<C-b>', ':lua require("dotnet_tools.helpers").dotnet_build_project()<CR>', { noremap = true, silent = true })

M.get_dll_path = function()
    local request = function()
        return vim.fn.input('Path to dll', vim.fn.getcwd(), 'file')
    end

    if vim.g['dotnet_last_dll_path'] == nil then
        vim.g['dotnet_last_dll_path'] = request()
    else
        if vim.fn.confirm('Do you want to change the path to dll?\n' .. vim.g['dotnet_last_dll_path'], '&yes\n&no', 2) == 1 then
            vim.g['dotnet_last_dll_path'] = request()
        end
    end

    return vim.g['dotnet_last_dll_path']
end


local number_indices = function(array)
  local result = {}
  for i, value in ipairs(array) do
    result[i] = i .. ": " .. value
  end
  return result
end

local display_options = function(prompt_title, options)
  options = number_indices(options)
  table.insert(options, 1, prompt_title)

  local choice = vim.fn.inputlist(options)

  if choice > 0 then
    return options[choice + 1]
  else
    return nil
  end
end


local file_selection = function(cmd, opts)
  local results = vim.fn.systemlist(cmd)

  if #results == 0 then
    print(opts.empty_message)
    return
  end

  if opts.allow_multiple then
    return results
  end

  local result = results[1]
  if #results > 1 then
    result = display_options(opts.multiple_title_message, results)
  end

  return result
end

vim.g.dotnet_dap_project_selection = function(project_path, allow_multiple)
  local check_csproj_cmd = string.format('find %s -type f -name "*.csproj"', project_path)
  local project_file = file_selection(check_csproj_cmd, {
    empty_message = 'No csproj files found in ' .. project_path,
    multiple_title_message = 'Select project:',
    allow_multiple = allow_multiple
  })
  return project_file
end

-- Function to find .dll files in bin/Debug directories
---
--- Attempts to pick a process smartly.
---
--- Does the following:
--- 1. Gets all project files
--- 2. Build filter
--- 2a. If a single project is found then will filter for processes ending with project name.
--- 2b. If multiple projects found then will filter for processes ending with any of the project file names.
--- 2c. If no project files found then will filter for processes starting with "dotnet"
--- 3. If a single process matches then auto selects it. If multiple found then displays it user for selection.
M.dap_smart_pick_process = function(dap_utils, project_path)
  local project_file = vim.g.dotnet_dap_project_selection(project_path, true)
  if project_file == nil then
    return
  end

  local filter = function(proc)
    if type(project_file) == "table" then
      for _, file in pairs(project_file) do
        local project_name = vim.fn.fnamemodify(file, ":t:r")
        if vim.endswith(proc.name, project_name) then
          return true
        end
      end
      return false
    elseif type(project_file) == "string" then
      local project_name = vim.fn.fnamemodify(project_file, ":t:r")
      return vim.startswith(proc.name, project_name or "dotnet")
    end
  end

  local processes = dap_utils.get_processes()
  processes = vim.tbl_filter(filter, processes)

  if #processes == 0 then
    print("No dotnet processes could be found automatically. Try 'Attach' instead")
    return
  end

  if #processes > 1 then
    return dap_utils.pick_process({
      filter = filter
    })
  end

  return processes[1].pid
end


M.get_function_name_with_treesitter = function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1] - 1
    local col = cursor[2]
    local parser = vim.treesitter.get_parser(0, 'c_sharp')
    if not parser then return end

    local tree = parser:parse()[1]
    local root = tree:root()

    -- Traverse up the tree from the current node until we find a method declaration
    local node = root:named_descendant_for_range(line, col, line, col)
    while node do
        if node:type() == 'method_declaration' then
            -- Get the name node
            local name_node = node:field('name')[1]

            if name_node then
                local function_name = vim.treesitter.get_node_text(name_node, 0)
                return function_name
            end
        end
        node = node:parent()
    end
end

M.get_class_name = function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1] - 1
    local col = cursor[2]
    local parser = vim.treesitter.get_parser()
    if not parser then return end
    local lang_tree = parser:language_for_range { line, col, line, col }
    for _, tree in ipairs(lang_tree:trees()) do
        local root = tree:root()
        -- Traverse up the tree from the current node until we find a class declaration
        local node = root:named_descendant_for_range(line, col, line, col)
        while node do
            if node:type() == 'class_declaration' then -- Adjust the type according to Treesitter's C# queries
                -- Assuming the class name is a direct child of the class declaration, which might need adjustments
                for child_node in node:iter_children() do
                    if child_node:type() == "identifier" then -- The type for the node containing the class name might need adjustments
                        local class_name = vim.treesitter.get_node_text(child_node, 0)
                        print("Class name: " .. class_name)
                        return class_name
                    end
                end
            end
            node = node:parent()
        end
    end
end

return M
