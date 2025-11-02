return {
    "creativenull/efmls-configs-nvim",
    version = "v1.9.0",
    config = function()
        require("config.efmls-config-nvim.init")
    end,
    dependencies = { "neovim/nvim-lspconfig" },
}
