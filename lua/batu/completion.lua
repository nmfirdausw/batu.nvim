local M = {}

---@class batu.CompletionConfig
---@field blink? boolean|table `true` installs and sets up blink.cmp (v2) instead of the built-in
---  completion, a table does the same with your `blink.cmp` options. `false` (default) uses the built-in.
---@field autoshow? boolean `true` opens the completion menu as you type. `false` (default) opens it only
---  on request: `<C-x><C-o>`, `<C-n>` or `<C-p>` (and `<Tab>` on the command line).

-- Letters, digits and underscore, so the menu opens as you type rather than only after `.` or `:`.
local trigger_chars = vim.split("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_", "")

---@type table<integer, true> clients whose trigger characters were already extended
local extended = {}

---@param autoshow boolean
local function native(autoshow)
  local group = vim.api.nvim_create_augroup("batu.completion", { clear = true })

  if autoshow then
    vim.api.nvim_create_autocmd("CmdlineChanged", {
      group = group,
      desc = "Auto-show the command-line completion menu",
      pattern = { ":", "/", "?" },
      callback = function()
        vim.fn.wildtrigger()
      end,
    })
  end

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    desc = autoshow and "Enable LSP completion, triggered as you type" or "Enable LSP completion on request",
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client or not client:supports_method("textDocument/completion", args.buf) then
        return
      end

      -- Attaching to another buffer must not extend the same server capabilities again.
      local provider = client.server_capabilities.completionProvider
      if autoshow and provider and not extended[client.id] then
        extended[client.id] = true
        local triggers = vim.list_extend(vim.deepcopy(provider.triggerCharacters or {}), trigger_chars)
        provider.triggerCharacters = vim.fn.uniq(vim.fn.sort(triggers))
      end

      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = autoshow })

      if not autoshow then
        -- Let <C-n>/<C-p> include the language server's items, next to <C-x><C-o>.
        vim.api.nvim_buf_call(args.buf, function()
          vim.opt_local.complete:append("o")
        end)
      end
    end,
  })
end

---@param autoshow boolean
---@return table blink.cmp options
local function blink_defaults(autoshow)
  -- <C-n>/<C-p> select when the menu is open, and open it with the first item selected otherwise.
  local open_or_select = {
    ["<C-n>"] = { "select_next", "show_and_insert", "fallback_to_mappings" },
    ["<C-p>"] = { "select_prev", "show_and_insert", "fallback_to_mappings" },
  }

  return {
    -- <CR> accepts the selected item, and inserts a newline when none is selected.
    keymap = vim.tbl_extend("error", { preset = "default", ["<CR>"] = { "accept", "fallback" } }, open_or_select),
    completion = {
      menu = { auto_show = autoshow },
      list = { selection = { preselect = false } },
    },
    cmdline = {
      keymap = vim.tbl_extend("error", { preset = "cmdline" }, open_or_select),
      completion = {
        -- Show the menu while typing, like the native command-line menu, instead of only on <Tab>.
        menu = { auto_show = autoshow },
        -- Nothing preselected, so <CR> runs the command unless you picked an item.
        list = { selection = { preselect = false } },
      },
    },
  }
end

---@param autoshow boolean
---@param opts? table blink.cmp options merged over the defaults
local function blink(autoshow, opts)
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
  blink_cmp.setup(vim.tbl_deep_extend("force", blink_defaults(autoshow), opts or {}))

  -- Must run before the language servers are enabled so they all advertise blink's capabilities.
  vim.lsp.config("*", { capabilities = blink_cmp.get_lsp_capabilities() })
end

---@param opts? batu.CompletionConfig
function M.setup(opts)
  local engine = opts and opts.blink
  local autoshow = opts and opts.autoshow or false
  if engine then
    blink(autoshow, type(engine) == "table" and engine or nil)
  else
    native(autoshow)
  end
end

return M
