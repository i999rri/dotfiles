vim.g.mapleader = "\\"

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

vim.keymap.set('n', '<C-p>', ':Telescope file_browser<CR>', { noremap = true, silent = true })

-- 誤動作を回避するために無効化
vim.keymap.set('n', 'p', '<Nop>', { noremap = true, silent = true })

vim.keymap.set('n', '<C-l>', ':Telescope live_grep<CR>', { noremap = true, silent = true })

-- Controll + j + k を押すことで Escape を同じ動きをするための設定
vim.keymap.set('i', '<C-j><C-k>', '<Esc>', { noremap = true, silent = true })
vim.keymap.set('i', '<C-k><C-j>', '<Esc>', { noremap = true, silent = true })  -- 順序が逆でも対応

-- 全てのマクロ記録関連キーを無効化
vim.keymap.set('n', 'q', '<Nop>', { silent = true })
vim.keymap.set('n', 'Q', '<Nop>', { silent = true })
vim.keymap.set('n', '@', '<Nop>', { silent = true })  -- マクロ実行も無効化
