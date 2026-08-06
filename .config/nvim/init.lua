require("config.lazy")

vim.cmd("colorscheme asiimov")

vim.opt.clipboard = "unnamedplus"

-- WSL では Windows 側のクリップボードを直接読み書きする。
-- WSLg を無効にしている (msrdc が Windows 側のフォーカスを奪うため) ので
-- Wayland のクリップボードが存在せず、nvim の自動検出も効かない。
-- wsl-copy / wsl-paste は NixOS 側で用意している。
if vim.fn.has("wsl") == 1 and vim.fn.executable("wsl-copy") == 1 then
    vim.g.clipboard = {
        name = "wsl-clipboard",
        copy = {
            ["+"] = "wsl-copy",
            ["*"] = "wsl-copy",
        },
        paste = {
            ["+"] = "wsl-paste",
            ["*"] = "wsl-paste",
        },
        -- Windows 側でコピーした内容を拾うため、nvim 内のキャッシュは使わない
        cache_enabled = false,
    }
end

vim.opt.number = true

-- normal では行末の 1 つ先にカーソルを置けないため、insert から抜けるたびに
-- カーソルが 1 文字左へ動く。onemore にすると行末の先に留まれるので、モードを
-- 切り替えても位置が変わらない。
--
-- 引き換えに $ が行末の 1 つ先を指すようになる点だけ挙動が変わる。
vim.opt.virtualedit = "onemore"

-- 既定では normal がブロック、insert が細い縦棒になる。桁が同じでも、ブロックは
-- 文字を覆い、縦棒は文字の左端に立つため、モードを切り替えるとカーソルが半文字
-- ぶん動いたように見える。全モードをブロックに揃えて見た目の位置を固定する。
vim.opt.guicursor = "a:block"

-- 行の表示
vim.opt.cursorline = true
vim.opt.cursorlineopt = "both"

-- noice.nvimを使うためデフォルトのcmdlineは非表示にする
vim.opt.cmdheight = 0

-- troubleのために記述
vim.diagnostic.config({ virtual_text = true })

-- nvimの外で変更された場合にバッファを自動的に再読み込みするための設定
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
    pattern = "*",
    command = "checktime",
})

-- ウインドウを離れたときにモードをリセットする処理は setup_ime_control() の中に移した。
-- あれは IME の切り替えとセットの処理で、insert のまま離れて戻ると IME が無効な状態で
-- 日本語を打とうとすることになるため normal に戻していた。IME 制御を行わない環境
-- (WSL など fcitx / ibus のない環境) では、モードだけ解除されて不便になる。

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

        " Markdown highlighting for documentation window (Visual Studio IntelliSense style)
        highlight @markup.heading guifg=#ff6b35 gui=bold
        highlight @markup.strong guifg=#e0e0e0 gui=bold
        highlight @markup.italic guifg=#9e9e9e gui=italic
        highlight @markup.raw.block guibg=#3a3a3a guifg=#66bb6a
        highlight @markup.raw guibg=#3a3a3a guifg=#ff9800
        highlight @markup.link guifg=#42a5f5 gui=underline
        highlight @markup.link.url guifg=#42a5f5 gui=underline
        highlight @markup.list guifg=#ff6b35
        highlight @text.literal guifg=#66bb6a
        highlight @text.uri guifg=#42a5f5 gui=underline
        highlight @text.emphasis guifg=#9e9e9e gui=italic
        highlight @text.strong guifg=#e0e0e0 gui=bold
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

local function lazygit_toggle()
    lazygit:toggle()
end

vim.keymap.set("n", "<Leader>k", lazygit_toggle, { noremap = true, silent = true })

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
                -- 離れる時に IME を戻すため、insert のままだと戻ってきた時に
                -- IME が無効な状態で日本語を打とうとすることになる。normal に
                -- 落としておく。IME 制御をしない環境ではモードを保つので、
                -- ここは制御が有効なときだけ行う
                if vim.bo.filetype ~= "toggleterm" then
                    vim.api.nvim_feedkeys(
                        vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
                        "n",
                        false
                    )
                end
            end,
        })
    end
end

setup_ime_control()
