require("config.lazy")

vim.cmd('colorscheme asiimov')

vim.opt.clipboard = "unnamedplus"

vim.opt.number = true

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.cmd([[
      highlight Normal guibg=none ctermbg=none
      highlight NonText guibg=none ctermbg=none
      highlight NormalNC guibg=none ctermbg=none
      highlight NormalSB guibg=none ctermbg=none
      highlight SignColumn guibg=none ctermbg=none
      highlight EndOfBuffer guibg=none ctermbg=none
      highlight LineNr guibg=none ctermbg=none
    ]])
  end,
})

-- 初回適用
vim.cmd([[
  highlight Normal guibg=none ctermbg=none
  highlight NonText guibg=none ctermbg=none
  highlight NormalNC guibg=none ctermbg=none
  highlight NormalSB guibg=none ctermbg=none
  highlight SignColumn guibg=none ctermbg=none
  highlight EndOfBuffer guibg=none ctermbg=none
  highlight LineNr guibg=none ctermbg=none
]])
