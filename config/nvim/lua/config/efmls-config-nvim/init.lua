-- Register linters and formatters per language
local eslint = require("efmls-configs.linters.eslint")
local prettier = require("efmls-configs.formatters.prettier")
local stylua = require("efmls-configs.formatters.stylua")
local languages = {
    lua = { stylua },
}

-- Or use the defaults provided by this plugin
-- check doc/SUPPORTED_LIST.md for the supported languages
--
-- local languages = require('efmls-configs.defaults').languages()

local efmls_config = {
    filetypes = vim.tbl_keys(languages),
    settings = {
        rootMarkers = { ".git/" },
        languages = languages,
    },
    init_options = {
        documentFormatting = true,
        documentRangeFormatting = true,
    },
}

vim.lsp.config("efm", vim.tbl_extend("force", efmls_config, {}))

vim.lsp.enable("efm")
