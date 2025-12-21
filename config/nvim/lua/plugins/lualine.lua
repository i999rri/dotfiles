return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    config = function()
        require("lualine").setup({
            options = {
                icons_enabled = true,
                theme = "auto",
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                disabled_filetypes = {
                    statusline = {},
                    winbar = { "snacks_dashboard" },
                },
                ignore_focus = {},
                always_divide_middle = true,
                always_show_tabline = true,
                globalstatus = false,
                refresh = {
                    statusline = 1000,
                    tabline = 1000,
                    winbar = 1000,
                    refresh_time = 16, -- ~60fps
                    events = {
                        "WinEnter",
                        "BufEnter",
                        "BufWritePost",
                        "SessionLoadPost",
                        "FileChangedShellPost",
                        "VimResized",
                        "Filetype",
                        "CursorMoved",
                        "CursorMovedI",
                        "ModeChanged",
                    },
                },
            },
            sections = {},
            inactive_sections = {},
            tabline = {},
            winbar = {
                lualine_c = { "filename" },
                lualine_x = { "diagnostics" },
            },
            inactive_winbar = {
                lualine_c = { "filename" },
            },
            extensions = {},
        })
    end,
}
