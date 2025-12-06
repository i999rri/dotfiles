require("config.lazy")

vim.cmd("colorscheme asiimov")

vim.opt.clipboard = "unnamedplus"

vim.opt.number = true

-- 行の表示
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"

-- troubleのために記述
vim.diagnostic.config { virtual_text = true }

-- @return void
local function vim_cmd()
    vim.cmd([[
        highlight Normal guibg=none ctermbg=none
        highlight NonText guibg=none ctermbg=none
        highlight NormalNC guibg=none ctermbg=none
        highlight NormalSB guibg=none ctermbg=none
        highlight SignColumn guibg=none ctermbg=none
        highlight EndOfBuffer guibg=none ctermbg=none
        highlight LineNr guibg=none ctermbg=none
    ]])
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = vim_cmd })

vim_cmd()

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

-- 折りたたみ関連
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = true
vim.opt.foldlevel = 99

-- statuscolumn
vim.opt.signcolumn = "yes"
vim.opt.foldcolumn = "1"
vim.opt.statuscolumn = " %s%C %l     "
