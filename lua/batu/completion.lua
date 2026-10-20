local M = {}

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

function M.setup()
  native()
end

return M
