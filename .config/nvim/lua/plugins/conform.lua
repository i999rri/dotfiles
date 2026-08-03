return {
  'stevearc/conform.nvim',
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      swift = { "swiftformat" }
    },
    default_format_opts = {
      lsp_format = "fallback",
    },
    format_on_save = function (buf)
        if vim.v.cmdarg == 1 then
            return nil
        end

        local name = vim.api.nvim_buf_get_name(buf)
        local basename = vim.fs.basename(name)

        if basename:match("%lock$") or basename:match("%plock%p") then
            return nil
        end

        return { timeout_ms = 500 }
    end,
  },
}
