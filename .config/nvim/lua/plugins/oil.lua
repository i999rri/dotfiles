return {
	"stevearc/oil.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local oil = require("oil")

		-- oil.nvim専用の背景色を設定（真っ白）
		vim.api.nvim_set_hl(0, "OilFloat", { bg = "#FFFFFF", fg = "#000000" })
		vim.api.nvim_set_hl(0, "OilFloatBorder", { bg = "#FFFFFF", fg = "#999999" })

		oil.setup({
			-- デフォルトのファイルエクスプローラーとして使用
			default_file_explorer = true,
			-- カラムの設定
			columns = {
				"icon",
			},
			-- バッファ設定
			buf_options = {
				buflisted = false,
				bufhidden = "hide",
			},
			-- ウィンドウ設定
			win_options = {
				wrap = false,
				signcolumn = "no",
				cursorcolumn = false,
				foldcolumn = "0",
				spell = false,
				list = false,
				conceallevel = 3,
				concealcursor = "nvic",
			},
			-- 削除時の確認
			delete_to_trash = false,
			skip_confirm_for_simple_edits = false,
			-- プロンプトの設定
			prompt_save_on_select_new_entry = true,
			-- 実験的機能
			experimental_watch_for_changes = false,
			-- oil.nvim内でのキーマップ
			keymaps = {
				["g?"] = "actions.show_help",
				["<CR>"] = "actions.select",
				["<C-s>"] = "actions.select_vsplit",
				["<C-h>"] = "actions.select_split",
				["<C-t>"] = "actions.select_tab",
				["<C-p>"] = "actions.preview",
				["<C-c>"] = "actions.close",
				["<C-l>"] = "actions.refresh",
				["-"] = "actions.parent",
				["_"] = "actions.open_cwd",
				["`"] = "actions.cd",
				["~"] = "actions.tcd",
				["gs"] = "actions.change_sort",
				["gx"] = "actions.open_external",
				["g."] = "actions.toggle_hidden",
				["g\\"] = "actions.toggle_trash",
			},
			-- 外部プログラムで開くコマンド
			use_default_keymaps = true,
			view_options = {
				-- 隠しファイルとディレクトリの表示
				show_hidden = false,
				-- oil.nvimが管理するファイルを非表示
				is_hidden_file = function(name, bufnr)
					return vim.startswith(name, ".")
				end,
				is_always_hidden = function(name, bufnr)
					return false
				end,
			},
			-- フローティングウィンドウの設定
			float = {
				padding = 2,
				max_width = 0,
				max_height = 0,
				border = "rounded",
				win_options = {
					winblend = 0, -- 完全に不透明
					cursorline = false, -- カーソル行のハイライトを無効化
					winhighlight = "Normal:OilFloat,FloatBorder:OilFloatBorder", -- 専用ハイライト適用
				},
				override = function(conf)
					-- 可変サイズ（画面の40%幅、60%高さ）
					local width = math.floor(vim.o.columns * 0.4)
					local height = math.floor(vim.o.lines * 0.6)

					-- 右上に配置
					conf.col = vim.o.columns - width
					conf.row = 0
					conf.width = width
					conf.height = height

					return conf
				end,
			},
		})

		-- <leader>e でフローティングウィンドウで開く
		vim.keymap.set("n", "<leader>e", function()
			require("oil").open_float()
		end, { desc = "Open oil in floating window" })

		-- - で親ディレクトリを通常のバッファで開く（オプション）
		vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
	end,
}
