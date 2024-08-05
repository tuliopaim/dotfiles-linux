local get_class_name = function()
    return vim.fn.expand('%:t:r')
end

local get_node_text = function(node, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local start_row, start_col, _, end_col = node:range()
  local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
  return line and string.sub(line, start_col + 1, end_col) or ""
end

local get_node_at_cursor = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  local col = cursor[2]
  local parser = vim.treesitter.get_parser()
  if not parser then
    return
  end
  local lang_tree = parser:language_for_range { line, col, line, col }
  for _, tree in ipairs(lang_tree:trees()) do
    local root = tree:root()
    local node = root:named_descendant_for_range(line, col, line, col)
    if node then
      return node
    end
  end
end

local get_test_name = function()
    local node = get_node_at_cursor()
    if not node then
        print ('No node found')
        return
    end

    return get_node_text(node)
end

local run_test_and_print = function(testCmd)

    vim.cmd('botright split')

    vim.cmd('resize 20')

    vim.cmd('terminal ' .. testCmd)

    vim.cmd('startinsert!')
end

local M = {}

M.test_at_cursor = function()
    local class_name = get_class_name()
    local test_name = get_test_name()

    if not test_name then
        print ('No test name found')
        return
    end

    local cmd = string.format('dotnet test --filter "%s.%s"', class_name, test_name)

    print("Running test: " .. cmd)

    run_test_and_print(cmd)
end

M.test_class = function()
    local class_name = get_class_name()

    local cmd = string.format("dotnet test --filter FullyQualifiedName~%s", class_name)

    run_test_and_print(cmd)
end

return M
