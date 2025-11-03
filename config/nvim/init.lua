require("config.lazy")

vim.cmd("colorscheme asiimov")

vim.opt.clipboard = "unnamedplus"

vim.opt.number = true

-- 行の表示
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"

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

vim.keymap.set("n", "<Leader><tab>", ":Telescope buffers<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<Leader>p", ":Telescope file_browser<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<C-p>", ":Telescope find_files<CR>", { noremap = true, silent = true })

-- 誤動作を回避するために無効化
vim.keymap.set("n", "p", "<Nop>", { noremap = true, silent = true })

vim.keymap.set("n", "<C-l>", ":Telescope live_grep<CR>", { noremap = true, silent = true })

-- Controll + j + k を押すことで Escape を同じ動きをするための設定
vim.keymap.set("i", "<C-j><C-k>", "<Esc>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-k><C-j>", "<Esc>", { noremap = true, silent = true }) -- 順序が逆でも対応

-- 全てのマクロ記録関連キーを無効化
vim.keymap.set("n", "q", "<Nop>", { silent = true })
vim.keymap.set("n", "Q", "<Nop>", { silent = true })
vim.keymap.set("n", "@", "<Nop>", { silent = true }) -- マクロ実行も無効化

-- 診断情報とLSP情報を組み合わせて表示
local function show_detailed_diagnostic()
    local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
    if #diagnostics > 0 then
        vim.diagnostic.open_float()
    else
        vim.lsp.buf.hover()
    end
end

vim.keymap.set("n", "<C-h>", show_detailed_diagnostic, { desc = "Show diagnostic or hover" })

local Terminal = require("toggleterm.terminal").Terminal

local lazygit = Terminal:new({
    cmd = "lazygit",
    dir = "git_dir",
    direction = "float",
    float_opts = {
        border = "rounded",
    },
    -- function to run on opening the terminal
    on_open = function(term)
        vim.cmd("startinsert!")
        vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
    end,
    -- function to run on closing the terminal
    on_close = function(term)
        vim.cmd("startinsert!")
    end,
})

function _lazygit_toggle()
    lazygit:toggle()
end

vim.api.nvim_set_keymap("n", "<Leader>k", "<cmd>lua _lazygit_toggle()<CR>", { noremap = true, silent = true })
