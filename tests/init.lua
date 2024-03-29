vim.o.swapfile = false
vim.bo.swapfile = false

vim.cmd([[set runtimepath+=.]])
vim.cmd([[set runtimepath+=./misc/neotest]])
vim.cmd([[set runtimepath+=./misc/plenary]])
vim.cmd([[set runtimepath+=./misc/treesitter]])

require("nvim-treesitter.configs").setup({
  ensure_installed = "python",
  sync_install = true,
})

require("neotest").setup({
  adapters = {
    require("neotest-mamba"),
  },
})
