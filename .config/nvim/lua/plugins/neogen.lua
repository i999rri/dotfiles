return {
    "danymat/neogen",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = function()
        require("neogen").setup({
            enabled = true,
            snippet_engine = "luasnip",
            languages = {
                lua = {
                    template = {
                        annotation_convention = "ldoc",
                    },
                },
                cs = {
                    template = {
                        annotation_convention = "xmldoc",
                    },
                },
                php = {
                    template = {
                        annotation_convention = "phpdoc",
                    },
                },
                rust = {
                    template = {
                        annotation_convention = "rustdoc",
                    },
                },
            },
        })

        -- Keymaps
        local opts = { noremap = true, silent = true }
        vim.keymap.set("n", "<Leader>nf", ":lua require('neogen').generate()<CR>", opts)
        vim.keymap.set("n", "<Leader>nc", ":lua require('neogen').generate({ type = 'class' })<CR>", opts)
        vim.keymap.set("n", "<Leader>nt", ":lua require('neogen').generate({ type = 'type' })<CR>", opts)
    end,
}
