-- ~/.config/nvim/lua/plugins/nvim-cmp.lua
return {
    "hrsh7th/nvim-cmp",
    event = "VeryLazy",
    dependencies = {
        -- 補完ソース
        "hrsh7th/cmp-buffer", -- バッファ内の単語
        "hrsh7th/cmp-path", -- ファイルパス
        "hrsh7th/cmp-cmdline", -- コマンドライン
        "hrsh7th/cmp-nvim-lsp", -- LSP
        "hrsh7th/cmp-nvim-lua", -- Neovim Lua API

        -- スニペット
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "rafamadriz/friendly-snippets",

        -- アイコン
        "onsails/lspkind.nvim",
    },
    config = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")
        local lspkind = require("lspkind")

        -- friendly-snippetsを読み込み
        require("luasnip.loaders.from_vscode").lazy_load()

        -- カスタムスニペットを読み込み
        require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/lua/snippets" })

        cmp.setup({
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end,
            },

            -- パフォーマンス設定
            performance = {
                debounce = 60,          -- デフォルト: 60ms（入力停止後の待機時間）
                throttle = 30,          -- デフォルト: 30ms
                fetching_timeout = 500, -- デフォルト: 500ms（LSPの応答待ち時間）
                max_view_entries = 50,  -- 表示する最大候補数
            },

            window = {
                completion = {
                    border = "none",
                    scrollbar = true,
                    winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None",
                },
                documentation = {
                    border = "none",
                    winhighlight = "Normal:Pmenu,FloatBorder:Pmenu",
                    max_width = 80,
                    max_height = 25,
                },
            },

            mapping = cmp.mapping.preset.insert({
                ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                ["<C-f>"] = cmp.mapping.scroll_docs(4),
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<C-e>"] = cmp.mapping.abort(),
                ["<CR>"] = cmp.mapping.confirm({ select = true }),

                -- Tab/Shift-Tabでスニペット移動
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item()
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    else
                        fallback()
                    end
                end, { "i", "s" }),

                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    elseif luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { "i", "s" }),
            }),

            sources = cmp.config.sources({
                { name = "skkeleton" },
                { name = "nvim_lsp" },
                { name = "luasnip" },
                { name = "nvim_lua" },
            }, {
                {
                    name = "buffer",
                    max_item_count = 10,
                    keyword_length = 3, -- 3文字以上で補完開始
                    option = {
                        get_bufnrs = function()
                            -- 表示中のバッファのみを対象
                            local bufs = {}
                            for _, win in ipairs(vim.api.nvim_list_wins()) do
                                bufs[vim.api.nvim_win_get_buf(win)] = true
                            end
                            return vim.tbl_keys(bufs)
                        end,
                    },
                },
                { name = "path" },
            }),

            formatting = {
                format = lspkind.cmp_format({
                    mode = "symbol_text",
                    maxwidth = 50,
                    ellipsis_char = "...",
                }),
            },
        })

        -- コマンドライン補完
        cmp.setup.cmdline({ "/", "?" }, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
                { name = "buffer" },
            },
        })

        cmp.setup.cmdline(":", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
                { name = "path" },
            }, {
                { name = "cmdline" },
            }),
        })
    end,
}
