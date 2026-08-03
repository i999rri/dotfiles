-- ~/.config/nvim/colors/asiimov.lua
-- CS:GO Asiimov風 Neovimカラースキーム (Dark)

-- カラースキームをクリア
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
end

vim.g.colors_name = "asiimov"

-- カラーパレット定義
local colors = {
    -- 基本色
    white = "#e0e0e0",
    black = "#1e1e1e",
    grey = "#9e9e9e",
    light_grey = "#6e6e6e",
    dark_grey = "#2a2a2a",

    -- Asiimovオレンジ系
    orange = "#ff6b35",
    light_orange = "#ff8c61",
    dark_orange = "#e55a2b",
    yellow_orange = "#ff9800",

    -- アクセント色
    blue = "#42a5f5",
    green = "#66bb6a",
    red = "#f44336",
    purple = "#ba68c8",
    cyan = "#26c6da",

    -- UI色
    bg = "#1e1e1e",
    fg = "#e0e0e0",
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
hi("Cursor", { fg = colors.black, bg = colors.cursor })
hi("CursorLine", { bg = colors.dark_grey })
hi("CursorColumn", { bg = colors.dark_grey })
hi("LineNr", { fg = colors.light_grey })
hi("CursorLineNr", { fg = colors.orange, style = "bold" })
hi("SignColumn", { bg = colors.bg })
hi("ColorColumn", { bg = colors.dark_grey })

-- 選択・検索
hi("Visual", { fg = colors.white, bg = colors.selection })
hi("Search", { fg = colors.white, bg = colors.dark_orange })
hi("IncSearch", { fg = colors.white, bg = colors.orange })

-- ステータスライン
hi("StatusLine", { fg = colors.black, bg = colors.orange })
hi("StatusLineNC", { fg = colors.grey, bg = colors.dark_grey })
hi("VertSplit", { fg = colors.dark_grey })

-- タブライン
hi("TabLine", { fg = colors.grey, bg = colors.dark_grey })
hi("TabLineFill", { bg = colors.dark_grey })
hi("TabLineSel", { fg = colors.black, bg = colors.orange })

-- ポップアップメニュー
hi("Pmenu", { fg = colors.fg, bg = colors.dark_grey })
hi("PmenuSel", { fg = colors.black, bg = colors.orange })
hi("PmenuSbar", { bg = "#3a3a3a" })
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
hi("MatchParen", { fg = colors.orange, bg = "#3a3a3a", style = "bold" })

-- 差分
hi("DiffAdd", { fg = colors.green, bg = "#1a3a1a" })
hi("DiffChange", { fg = colors.yellow_orange, bg = "#3a2a1a" })
hi("DiffDelete", { fg = colors.red, bg = "#3a1a1a" })
hi("DiffText", { fg = colors.black, bg = colors.yellow_orange })

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
hi("NvimTreeNormal", { fg = colors.fg, bg = colors.dark_grey })
hi("NvimTreeFolderName", { fg = colors.blue })
hi("NvimTreeFolderIcon", { fg = colors.orange })
hi("NvimTreeOpenedFolderName", { fg = colors.blue, style = "bold" })
hi("NvimTreeRootFolder", { fg = colors.orange, style = "bold" })
hi("NvimTreeSpecialFile", { fg = colors.orange })
hi("NvimTreeExecFile", { fg = colors.green })

-- Telescope
hi("TelescopeSelection", { fg = colors.black, bg = colors.orange })
hi("TelescopeSelectionCaret", { fg = colors.orange })
hi("TelescopeMatching", { fg = colors.orange, style = "bold" })

-- indent-blankline
hi("IblIndent", { fg = "#3a3a3a" }) -- インデント線の色
hi("IblScope", { fg = colors.orange }) -- 現在のスコープの色
