require("config.lazy")

vim.opt.clipboard = "unnamedplus"

vim.opt.number = true

vim.cmd([[
  highlight Normal guibg=none
  highlight NonText guibg=none
  highlight Normal ctermbg=none
  highlight NonText ctermbg=none
  highlight NormalNC guibg=none
  highlight NormalSB guibg=none
  highlight LineNr guifg=Black guibg=DarkGray ctermfg=Black ctermbg=DarkGray
]])
