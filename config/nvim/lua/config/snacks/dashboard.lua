-- ~/.config/nvim/lua/config/dashboard.lua

local M = {}

-- ダッシュボードのアスキーアート
local header = {}

-- ダッシュボードのボタン設定
M.buttons = {
    { icon = " ", key = "f", desc = "Find File", action = ":Telescope find_files" },
    { icon = " ", key = "p", desc = "Find Project", action = ":Telescope projects" },
    { icon = " ", key = "r", desc = "Recent Files", action = ":Telescope oldfiles" },
    { icon = " ", key = "c", desc = "Config", action = ":Telescope find_files cwd=" .. vim.fn.stdpath("config") },
    { icon = " ", key = "s", desc = "Restore Session", section = "session" },
    { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
    { icon = " ", key = "q", desc = "Quit", action = ":qa" },
}

-- セクション設定
M.sections = {
    { pane = 2, section = "header" },
    { pane = 1, section = "keys", gap = 1, padding = 1 },
    { pane = 1, section = "startup" },
}

-- ダッシュボードの設定オブジェクト
M.dashboard_config = {
    width = 60,
    row = nil, -- 画面中央に表示
    col = nil, -- 画面中央に表示
    pane_gap = 4, -- ペイン間のギャップ
    autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", -- 自動キー割り当て
    -- テーマ設定
    preset = {
        header = table.concat(header, "\n"),
        keys = M.buttons,
    },
    sections = M.sections,
    formats = {
        key = function(item)
            return { { "[", hl = "special" }, { item.key, hl = "key" }, { "]", hl = "special" } }
        end,
    },
}

return M
