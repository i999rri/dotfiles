return {
    { "rinx/cmp-skkeleton", after = { "nvim-cmp", "skkeleton" } },
    { "delphinus/skkeleton_indicator.nvim", opts = {} },
    {
        "vim-denops/denops.vim",
        lazy = false, -- Nvim起動時にすぐロード
    },
    {
        "vim-skk/skkeleton",
        dependencies = { "vim-denops/denops.vim" },
        config = function()
            vim.fn["skkeleton#config"]({
                globalDictionaries = { "~/.skk/SKK-JISYO.L" },
                userDictionary = "~/.skk/skkeleton-jisyo",
                immediatelyDictionaryRW = true,
                showCandidatesCount = 1,
                eggLikeNewline = true,
            })

            -- Ctrl+j で日本語入力モード切替
            vim.keymap.set({ "i", "c" }, "<C-j>", "<Plug>(skkeleton-toggle)")
        end,
    },
}
