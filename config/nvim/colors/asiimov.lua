-- ~/.config/nvim/colors/asiimov.lua
-- CS:GO Asiimov風 Neovimカラースキーム

-- カラースキームをクリア
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
end

vim.g.colors_name = "asiimov"

-- カラーパレット定義
local colors = {
    -- 基本色
    white = "#f5f5f5",
    black = "#0f0f0f",
    grey = "#2d2d2d",
    light_grey = "#9e9e9e",

    -- Asiimovオレンジ系
    orange = "#ff6b35",
    light_orange = "#ff8c61",
    dark_orange = "#e55a2b",
    yellow_orange = "#ff9800",

    -- アクセント色
    blue = "#2196f3",
    green = "#4caf50",
    red = "#f44336",
    purple = "#9c27b0",
    cyan = "#00bcd4",

    -- UI色
    bg = "#f5f5f5",
    fg = "#0f0f0f",
    cursor = "#ff6b35",
    selection = "#ff6b35",
    comment = "#9e9e9e",
}

-- ハイライト関数
local function hi(group, opts)
    local cmd = "hi " .. group
    if opts.fg then
        cmd = cmd .. " guifg=" .. opts.fg
    end
    if opts.bg then
        cmd = cmd .. " guibg=" .. opts.bg
    end
    if opts.style then
        cmd = cmd .. " gui=" .. opts.style
    end
    vim.cmd(cmd)
end

-- 基本UI
hi("Normal", { fg = colors.fg, bg = colors.bg })
hi("Cursor", { fg = colors.white, bg = colors.cursor })
hi("CursorLine", { bg = "#eeeeee" })
hi("CursorColumn", { bg = "#eeeeee" })
hi("LineNr", { fg = colors.light_grey })
hi("CursorLineNr", { fg = colors.orange, style = "bold" })
hi("SignColumn", { bg = colors.bg })
hi("ColorColumn", { bg = "#eeeeee" })

-- 選択・検索
hi("Visual", { fg = colors.white, bg = colors.selection })
hi("Search", { fg = colors.white, bg = colors.dark_orange })
hi("IncSearch", { fg = colors.white, bg = colors.orange })

-- ステータスライン
hi("StatusLine", { fg = colors.white, bg = colors.orange })
hi("StatusLineNC", { fg = colors.grey, bg = "#e0e0e0" })
hi("VertSplit", { fg = "#e0e0e0" })

-- タブライン
hi("TabLine", { fg = colors.grey, bg = "#e0e0e0" })
hi("TabLineFill", { bg = "#e0e0e0" })
hi("TabLineSel", { fg = colors.white, bg = colors.orange })

-- ポップアップメニュー
hi("Pmenu", { fg = colors.fg, bg = "#eeeeee" })
hi("PmenuSel", { fg = colors.white, bg = colors.orange })
hi("PmenuSbar", { bg = "#e0e0e0" })
hi("PmenuThumb", { bg = colors.orange })

-- エラー・警告
hi("Error", { fg = colors.red, style = "bold" })
hi("ErrorMsg", { fg = colors.red, style = "bold" })
hi("WarningMsg", { fg = colors.yellow_orange, style = "bold" })

-- 構文ハイライト
hi("Comment", { fg = colors.comment, style = "italic" })
hi("Todo", { fg = colors.orange, bg = colors.bg, style = "bold" })

-- 定数・文字列
hi("Constant", { fg = colors.orange })
hi("String", { fg = colors.green })
hi("Character", { fg = colors.green })
hi("Number", { fg = colors.orange })
hi("Boolean", { fg = colors.orange })
hi("Float", { fg = colors.orange })

-- 識別子
hi("Identifier", { fg = colors.blue })
hi("Function", { fg = colors.blue, style = "bold" })

-- ステートメント
hi("Statement", { fg = colors.orange, style = "bold" })
hi("Conditional", { fg = colors.orange, style = "bold" })
hi("Repeat", { fg = colors.orange, style = "bold" })
hi("Label", { fg = colors.orange })
hi("Operator", { fg = colors.grey })
hi("Keyword", { fg = colors.orange, style = "bold" })
hi("Exception", { fg = colors.red, style = "bold" })

-- プリプロセッサ
hi("PreProc", { fg = colors.purple })
hi("Include", { fg = colors.purple })
hi("Define", { fg = colors.purple })
hi("Macro", { fg = colors.purple })
hi("PreCondit", { fg = colors.purple })

-- 型
hi("Type", { fg = colors.blue, style = "bold" })
hi("StorageClass", { fg = colors.blue })
hi("Structure", { fg = colors.blue })
hi("Typedef", { fg = colors.blue })

-- 特殊文字
hi("Special", { fg = colors.orange })
hi("SpecialChar", { fg = colors.light_orange })
hi("Tag", { fg = colors.orange })
hi("Delimiter", { fg = colors.grey })
hi("SpecialComment", { fg = colors.comment, style = "bold" })
hi("Debug", { fg = colors.red })

-- マッチング括弧
hi("MatchParen", { fg = colors.orange, bg = "#e8e8e8" })

-- 差分
hi("DiffAdd", { fg = colors.green, bg = "#e8f5e8" })
hi("DiffChange", { fg = colors.yellow_orange, bg = "#fff3e0" })
hi("DiffDelete", { fg = colors.red, bg = "#ffebee" })
hi("DiffText", { fg = colors.white, bg = colors.yellow_orange })

-- Git関連 (vim-gitgutter等)
hi("GitGutterAdd", { fg = colors.green })
hi("GitGutterChange", { fg = colors.yellow_orange })
hi("GitGutterDelete", { fg = colors.red })

-- LSP関連
hi("LspDiagnosticsDefaultError", { fg = colors.red })
hi("LspDiagnosticsDefaultWarning", { fg = colors.yellow_orange })
hi("LspDiagnosticsDefaultInformation", { fg = colors.blue })
hi("LspDiagnosticsDefaultHint", { fg = colors.comment })

-- Tree-sitter (nvim-treesitter)
hi("@comment", { fg = colors.comment, style = "italic" })
hi("@keyword", { fg = colors.orange, style = "bold" })
hi("@string", { fg = colors.green })
hi("@number", { fg = colors.orange })
hi("@boolean", { fg = colors.orange })
hi("@function", { fg = colors.blue, style = "bold" })
hi("@type", { fg = colors.blue })
hi("@variable", { fg = colors.fg })
hi("@constant", { fg = colors.orange })
hi("@operator", { fg = colors.grey })

-- NvimTree
hi("NvimTreeNormal", { fg = colors.fg, bg = "#eeeeee" })
hi("NvimTreeFolderName", { fg = colors.blue })
hi("NvimTreeFolderIcon", { fg = colors.orange })
hi("NvimTreeOpenedFolderName", { fg = colors.blue, style = "bold" })
hi("NvimTreeRootFolder", { fg = colors.orange, style = "bold" })
hi("NvimTreeSpecialFile", { fg = colors.orange })
hi("NvimTreeExecFile", { fg = colors.green })

-- Telescope
hi("TelescopeSelection", { fg = colors.white, bg = colors.orange })
hi("TelescopeSelectionCaret", { fg = colors.orange })
hi("TelescopeMatching", { fg = colors.orange, style = "bold" })

-- indent-blankline
hi("IblIndent", { fg = "#c0c0c0" }) -- インデント線の色
hi("IblScope", { fg = colors.orange }) -- 現在のスコープの色
