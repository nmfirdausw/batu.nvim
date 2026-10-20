local M = {}

---@class batu.CompletionConfig
---@field blink? boolean|table `true` installs and sets up blink.cmp (v2) instead of the built-in
---  completion, a table does the same with your `blink.cmp` options. `false` (default) uses the built-in.

-- Letters, digits and underscore, so the menu opens as you type rather than only after `.` or `:`.
local trigger_chars = vim.split("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_", "")

---@type table<integer, true> clients whose trigger characters were already extended
local extended = {}

local function native()
  local group = vim.api.nvim_create_augroup("batu.completion", { clear = true })

  vim.api.nvim_create_autocmd("CmdlineChanged", {
    group = group,
    desc = "Auto-show the command-line completion menu",
    pattern = { ":", "/", "?" },
    callback = function()
      vim.fn.wildtrigger()
    end,
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    desc = "Enable LSP completion, triggered as you type",
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client or not client:supports_method("textDocument/completion", args.buf) then
        return
      end

      -- Attaching to another buffer must not extend the same server capabilities again.
      local provider = client.server_capabilities.completionProvider
      if provider and not extended[client.id] then
        extended[client.id] = true
        local triggers = vim.list_extend(vim.deepcopy(provider.triggerCharacters or {}), trigger_chars)
        provider.triggerCharacters = vim.fn.uniq(vim.fn.sort(triggers))
      end

      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end,
  })
end

---@param opts? table blink.cmp options
local function blink(opts)
  if vim.fn.executable("cargo") == 0 then
    error("batu.completion: blink.cmp needs `cargo` to build its fuzzy matcher, install Rust (https://rustup.rs)", 0)
  end

  vim.pack.add({
    -- blink.cmp v2 (main) requires blink.lib, and must find it when it loads.
    "https://github.com/saghen/blink.lib",
    { src = "https://github.com/saghen/blink.cmp", version = "main" },
  })

  local blink_cmp = require("blink.cmp")

  -- v2 has no prebuilt binaries for main. This builds the Rust fuzzy matcher on first run and after
  -- an update, and does nothing otherwise.
  blink_cmp.build():pwait()
  blink_cmp.setup(opts)

  -- Must run before the language servers are enabled so they all advertise blink's capabilities.
  vim.lsp.config("*", { capabilities = blink_cmp.get_lsp_capabilities() })
end

---@param opts? batu.CompletionConfig
function M.setup(opts)
  local engine = opts and opts.blink
  if engine then
    blink(type(engine) == "table" and engine or nil)
  else
    native()
  end
end

return M
