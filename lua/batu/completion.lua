local M = {}

---@class batu.CompletionConfig
---@field blink? boolean|table `true` installs and sets up blink.cmp (v2) instead of the built-in
---  completion, a table does the same with your `blink.cmp` options. `false` (default) uses the built-in.
---@field autoshow? boolean `true` opens the completion menu as you type. `false` (default) opens it only
---  on request: `<C-x><C-o>`, `<C-n>` or `<C-p>` (and `<Tab>` on the command line).
---@field documentation? boolean `true` shows the documentation of the selected item next to the menu.
---  `false` (default) shows none.
---@field signature_help? boolean `true` shows the signature help while typing a call's arguments. `false`
---  (default) shows none.

-- Letters, digits and underscore, so the menu opens as you type rather than only after `.` or `:`.
local trigger_chars = vim.split("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_", "")

---@type table<integer, true> clients whose trigger characters were already extended
local extended = {}

local function show_signature_help()
  vim.lsp.buf.signature_help({ silent = true })
end

---@return integer? win the signature help float, when open
local function signature_win()
  local win = vim.b.lsp_floating_preview
  if win and vim.api.nvim_win_is_valid(win) and vim.w[win]["textDocument/signatureHelp"] then
    return win
  end
end

---@param key string key to send when there is nothing to scroll
---@param direction 1|-1
local function scroll_documentation(key, direction)
  local win = vim.fn.complete_info({ "preview_winid" }).preview_winid
  if not win or win <= 0 or not vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_feedkeys(vim.keycode(key), "n", false)
    return
  end

  local lines = math.max(1, math.floor(vim.api.nvim_win_get_height(win) / 2))
  vim.api.nvim_win_call(win, function()
    vim.cmd(("normal! %d%s"):format(lines, direction > 0 and vim.keycode("<C-e>") or vim.keycode("<C-y>")))
  end)
end

---@param opts { autoshow: boolean, documentation: boolean, signature_help: boolean }
local function native(opts)
  local autoshow = opts.autoshow
  local group = vim.api.nvim_create_augroup("batu.completion", { clear = true })

  if opts.documentation then
    vim.opt.completeopt:append("popup")
  end

  -- The same keys as blink.cmp's default preset.
  vim.keymap.set("i", "<C-k>", function()
    local win = signature_win()
    if win then
      vim.api.nvim_win_close(win, true)
    else
      vim.lsp.buf.signature_help({ silent = true })
    end
  end, { desc = "Toggle signature help" })
  vim.keymap.set("i", "<C-f>", function()
    scroll_documentation("<C-f>", 1)
  end, { desc = "Scroll completion documentation down" })
  vim.keymap.set("i", "<C-b>", function()
    scroll_documentation("<C-b>", -1)
  end, { desc = "Scroll completion documentation up" })

  if opts.signature_help then
    -- An accepted item can end in a call, such as a snippet with `(`, and no key was typed for it.
    vim.api.nvim_create_autocmd("CompleteDone", {
      group = group,
      desc = "Show signature help after accepting a completion item",
      callback = function()
        if vim.v.completed_item.word then
          vim.schedule(function()
            if vim.api.nvim_get_mode().mode == "i" then
              show_signature_help()
            end
          end)
        end
      end,
    })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = group,
      desc = "Show signature help when a trigger character is typed",
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local provider = client and client.server_capabilities.signatureHelpProvider
        if not provider then
          return
        end

        local triggers = vim.list_extend(
          vim.deepcopy(provider.triggerCharacters or {}),
          provider.retriggerCharacters or {}
        )
        vim.api.nvim_create_autocmd("InsertCharPre", {
          group = group,
          buffer = args.buf,
          desc = "Show signature help",
          callback = function()
            if vim.tbl_contains(triggers, vim.v.char) then
              vim.schedule(show_signature_help)
            end
          end,
        })
      end,
    })
  end

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

---@param opts { autoshow: boolean, documentation: boolean, signature_help: boolean }
---@return table blink.cmp options
local function blink_defaults(opts)
  local autoshow = opts.autoshow
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
      documentation = { auto_show = opts.documentation },
      list = { selection = { preselect = false } },
    },
    -- Also show it after accepting an item, which a typed trigger character does not cover.
    signature = { enabled = opts.signature_help, trigger = { show_on_accept = true } },
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

---@param settings { autoshow: boolean, documentation: boolean, signature_help: boolean }
---@param opts? table blink.cmp options merged over the defaults
local function blink(settings, opts)
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
  blink_cmp.setup(vim.tbl_deep_extend("force", blink_defaults(settings), opts or {}))

  -- Must run before the language servers are enabled so they all advertise blink's capabilities.
  vim.lsp.config("*", { capabilities = blink_cmp.get_lsp_capabilities() })
end

---@param opts? batu.CompletionConfig
function M.setup(opts)
  local engine = opts and opts.blink
  local settings = {
    autoshow = opts and opts.autoshow or false,
    documentation = opts and opts.documentation or false,
    signature_help = opts and opts.signature_help or false,
  }
  if engine then
    blink(settings, type(engine) == "table" and engine or nil)
  else
    native(settings)
  end
end

return M
