require("config.lazy")

vim.cmd("colorscheme asiimov")

vim.opt.clipboard = "unnamedplus"

vim.opt.number = true

-- 行の表示
vim.opt.cursorline = true
vim.opt.cursorlineopt = "both"

-- troubleのために記述
vim.diagnostic.config({ virtual_text = true })

-- nvimの外で変更された場合にバッファを自動的に再読み込みするための設定
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
    pattern = "*",
    command = "checktime",
})

-- ウインドウを離れて戻った時にはどのモードであったかを覚えていないため、ウインドウを離れたときは常にモードをリセットする
vim.api.nvim_create_autocmd("FocusLost", {
    pattern = "*",
    callback = function()
        if vim.bo.filetype == "toggleterm" then
            return
        end

        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    end,
})

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
        highlight link CmpItemAbbr Normal
        highlight link CmpItemAbbrMatch Normal
        highlight link CmpItemAbbrMatchFuzzy Normal
        highlight link CmpItemKind Normal
        highlight link CmpItemMenu Normal
    ]])
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = vim_cmd })

vim_cmd()

vim.keymap.set("n", "<Leader><tab>", "<cmd>lua require('fzf-lua').buffers()<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<Leader>p", "<cmd>lua require('fzf-lua').files()<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<C-p>", "<cmd>lua require('fzf-lua').files()<CR>", { noremap = true, silent = true })

-- 誤動作を回避するために無効化
vim.keymap.set("n", "p", "<Nop>", { noremap = true, silent = true })

vim.keymap.set("n", "<C-l>", "<cmd>lua require('fzf-lua').live_grep()<CR>", { noremap = true, silent = true })

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

-- ステータスラインを表示する必要がないため、非表示の設定をしている
vim.opt.laststatus = 0
vim.opt.statusline = "─"
vim.opt.fillchars:append({ stl = "─", stlnc = "─" })

local function setup_ime_control()
    local ime_disable, ime_enable

    if vim.fn.has("mac") == 1 then
        -- macOS
        ime_disable = "im-select com.apple.keylayout.ABC"
        ime_enable = "im-select com.apple.inputmethod.Kotoeri.Japanese"
    elseif vim.fn.has("unix") == 1 then
        -- Linux
        if vim.fn.executable("fcitx-remote") == 1 then
            ime_disable = "fcitx-remote -c"
            ime_enable = "fcitx-remote -o"
        elseif vim.fn.executable("ibus") == 1 then
            ime_disable = "ibus engine xkb:us::eng"
            ime_enable = "ibus engine mozc-jp"
        end
    elseif vim.fn.has("win32") == 1 then
        -- Windows
        ime_disable = nil
        ime_enable = nil
    end

    if ime_disable and ime_enable then
        vim.api.nvim_create_autocmd("FocusGained", {
            pattern = "*",
            callback = function()
                vim.fn.system(ime_disable)
            end,
        })

        vim.api.nvim_create_autocmd("FocusLost", {
            pattern = "*",
            callback = function()
                vim.fn.system(ime_enable)
            end,
        })
    end
end

setup_ime_control()
