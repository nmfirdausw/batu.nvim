local M = {}

---@class batu.LspConfig
---@field lspconfig? boolean `true` installs and loads nvim-lspconfig (via `vim.pack`), which provides
---  ready-made configs for most servers. `false` (default) leaves server configs to you: put them in
---  `lsp/<name>.lua` in your Neovim config.
---@field servers? table<string, boolean|table> The servers to enable, by name. `true` uses the config
---  Neovim finds for it (nvim-lspconfig's, or your own `lsp/<name>.lua`), a table is merged on top of
---  that config first, `false` skips it.

---@param opts? batu.LspConfig
function M.setup(opts)
  opts = opts or {}

  if opts.lspconfig then
    vim.pack.add({ "https://github.com/neovim/nvim-lspconfig" })
  end

  for name, server in pairs(opts.servers or {}) do
    if server ~= false then
      if type(server) == "table" then
        vim.lsp.config(name, server)
      end
      vim.lsp.enable(name)
    end
  end
end

return M
