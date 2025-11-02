return {
    "ahmedkhalf/project.nvim",
    config = function()
        require("project_nvim").setup({
            -- プロジェクト検出パターン
            patterns = { ".git", "Makefile", "package.json" },

            -- 除外するパス
            exclude_dirs = {},

            -- 自動でcdするか
            detection_methods = { "lsp", "pattern" },

            -- 手動モード（falseで自動検出）
            manual_mode = false,

            -- ルートディレクトリを表示するか
            show_hidden = false,

            -- 無効なプロジェクトを自動削除
            silent_chdir = true,

            -- スコープ設定
            scope_chdir = "global",
        })

        -- Telescopeにproject extensionを読み込み
        require("telescope").load_extension("projects")
    end,
}
