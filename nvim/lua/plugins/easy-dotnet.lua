return {
  "GustavEikaas/easy-dotnet.nvim",
  lazy = true,
  dependencies = { "nvim-lua/plenary.nvim", 'nvim-telescope/telescope.nvim', },
  config = function()
    require("easy-dotnet").setup({})
  end
}
