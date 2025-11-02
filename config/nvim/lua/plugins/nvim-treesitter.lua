return {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        local configs = require("nvim-treesitter.configs")

        configs.setup({
            ensure_installed = { "lua", "php", "c_sharp", "tsx", "typescript" },
            highlight = {
                enable = true,
            },
            additional_vim_regex_highlighting = false,
        })
    end,
}
