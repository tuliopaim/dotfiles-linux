---@type MappingsTable
local M = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },
    ["<leader>."] = {"<cmd> NvimTreeToggle <CR>", "Toggle nvimtree"}
  },
}

-- more keybinds!

return M
