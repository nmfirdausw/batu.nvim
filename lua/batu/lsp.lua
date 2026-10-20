local M = {}

---@class batu.LspConfig
---@field lspconfig? boolean `true` installs and loads nvim-lspconfig (via `vim.pack`), which provides
---  ready-made configs for most servers. `false` (default) leaves server configs to you: put them in
---  `lsp/<name>.lua` in your Neovim config.
---@field servers? table<string, boolean|table> The servers to enable, by name. `true` uses the config
---  Neovim finds for it (nvim-lspconfig's, or your own `lsp/<name>.lua`), a table is merged on top of
---  that config first, `false` skips it.
---@field inlay_hints? boolean `true` shows inlay hints in buffers whose server supports them. Default `false`.
---@field codelens? boolean `true` shows code lenses in buffers whose server supports them. Default `false`.
---@field keymaps? boolean `true` (default) sets `grh` and `grl` to toggle inlay hints and code lenses in
---  buffers whose server supports them. `false` sets none.

---@param opts batu.LspConfig
local function on_attach(opts)
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("batu.lsp", { clear = true }),
    desc = "Enable inlay hints and code lenses, and set their toggle keymaps",
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local buf = args.buf
      if not client then
        return
      end

      if client:supports_method("textDocument/inlayHint", buf) then
        if opts.inlay_hints then
          vim.lsp.inlay_hint.enable(true, { bufnr = buf })
        end
        if opts.keymaps ~= false then
          vim.keymap.set("n", "grh", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
          end, { buffer = buf, desc = "Toggle inlay hints" })
        end
      end

      if client:supports_method("textDocument/codeLens", buf) then
        if opts.codelens then
          vim.lsp.codelens.enable(true, { bufnr = buf })
        end
        if opts.keymaps ~= false then
          vim.keymap.set("n", "grl", function()
            vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled({ bufnr = buf }), { bufnr = buf })
          end, { buffer = buf, desc = "Toggle code lenses" })
        end
      end
    end,
  })
end

---@param opts? batu.LspConfig
function M.setup(opts)
  opts = opts or {}
  on_attach(opts)

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
