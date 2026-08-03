return {
    "mason-org/mason-lspconfig.nvim",
    opts = {},
    dependencies = {
        { "mason-org/mason.nvim", opts = {} },
        "neovim/nvim-lspconfig",
    },
    config = function()
        local masonLspConfig = require("mason-lspconfig")

        masonLspConfig.setup({
            automatic_enable = true,
        })
    end,
}
