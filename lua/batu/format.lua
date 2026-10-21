local M = {}

---@class batu.FormatConfig
---@field on_save? boolean `true` formats the buffer before every write. `false` (default) formats only on
---  request. Set `vim.b.format_on_save` to `true` or `false` to override this for one buffer.
---@field timeout_ms? integer How long a language server may take to format, in milliseconds. Default 1000.

---@type { on_save: boolean, timeout_ms: integer, ready: boolean }
local state = { on_save = false, timeout_ms = 1000, ready = false }

---@param expr string
local function is_lsp_formatexpr(expr)
  return expr:find("vim.lsp.formatexpr", 1, true) ~= nil
end

---@param buf integer
---@return boolean
local function uses_gq(buf)
  local expr = vim.api.nvim_get_option_value("formatexpr", { buf = buf })
  local prg = vim.api.nvim_get_option_value("formatprg", { buf = buf })
  -- A server's default `formatexpr` is attached after your ftplugin ran, so it would win over a
  -- `formatprg` you set there. A `formatprg` is explicit, so it wins here. Without one the server
  -- formats below, with a timeout and a check that it can, because `gq` would otherwise fall back to
  -- wrapping lines at 'textwidth'.
  if expr ~= "" and not is_lsp_formatexpr(expr) then
    return true
  end
  return prg ~= ""
end

---@param buf integer
---@param range? {[1]: integer, [2]: integer} first and last line, 1-based. The whole buffer when omitted.
local function format_with_gq(buf, range)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  ---@type string?
  local failure
  vim.api.nvim_buf_call(buf, function()
    local view = vim.fn.winsaveview()
    local first, last = unpack(range or { 1, vim.api.nvim_buf_line_count(buf) })

    -- Let `formatprg` through when only the server's default `formatexpr` stands in the way.
    local expr = vim.bo[buf].formatexpr
    local lsp_default = is_lsp_formatexpr(expr)
    if lsp_default then
      vim.bo[buf].formatexpr = ""
    end
    local ok, err = pcall(vim.cmd, ("silent keepjumps keepmarks normal! %dGgq%dG"):format(first, last))
    if lsp_default then
      vim.bo[buf].formatexpr = expr
    end
    if not ok then
      error(err, 0)
    end
    -- A failing `formatprg` leaves its error output in place of the text.
    if vim.v.shell_error ~= 0 then
      -- Only the formatted lines hold the output, those before and after are untouched.
      local after = #lines - last
      local output = vim.api.nvim_buf_get_lines(buf, first - 1, vim.api.nvim_buf_line_count(buf) - after, false)
      local message = vim.trim(table.concat(output, "\n"))
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      local prg = vim.api.nvim_get_option_value("formatprg", { buf = buf })
      failure = ("batu: formatprg `%s` failed (exit %d), buffer left unchanged:\n%s"):format(
        prg,
        vim.v.shell_error,
        message
      )
    end
    vim.fn.winrestview(view)
  end)

  if failure then
    vim.notify(failure, vim.log.levels.ERROR)
  end
end

---@param buf integer
---@param range? {[1]: integer, [2]: integer}
local function format_with_lsp(buf, range)
  if #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/formatting" }) == 0 then
    return
  end
  local opts = { bufnr = buf, timeout_ms = state.timeout_ms }
  if range then
    local last_line = vim.api.nvim_buf_get_lines(buf, range[2] - 1, range[2], false)[1] or ""
    opts.range = { start = { range[1], 0 }, ["end"] = { range[2], #last_line } }
  end
  vim.lsp.buf.format(opts)
end

--- Formats the buffer with `gq`'s own settings: 'formatexpr' or 'formatprg' when you set one, otherwise
--- the language server.
---@param buf? integer
---@param range? {[1]: integer, [2]: integer} first and last line, 1-based. The whole buffer when omitted.
function M.format(buf, range)
  buf = buf or vim.api.nvim_get_current_buf()
  if uses_gq(buf) then
    format_with_gq(buf, range)
  else
    format_with_lsp(buf, range)
  end
end

--- `gq` that keeps your text when a `formatprg` or custom `formatexpr` fails. Anything else is left to
--- Neovim's own `gq`. Called as an 'operatorfunc'.
function M.operatorfunc()
  local buf = vim.api.nvim_get_current_buf()
  local first, last = vim.fn.line("'["), vim.fn.line("']")
  if uses_gq(buf) then
    format_with_gq(buf, { first, last })
  else
    vim.cmd(("silent keepjumps keepmarks normal! %dGgq%dG"):format(first, last))
  end
end

--- Right-hand side for a `gq` mapping: sets the operator and starts it. Use it with `expr = true`.
---@param linewise? boolean `true` for `gqq`, which formats the current line
---@return string
function M.gq(linewise)
  vim.o.operatorfunc = "v:lua.require'batu.format'.operatorfunc"
  return linewise and "g@_" or "g@"
end

--- Formats the lines of the visual selection, and leaves visual mode.
function M.format_selection()
  local first, last = vim.fn.line("v"), vim.fn.line(".")
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  M.format(nil, { math.min(first, last), math.max(first, last) })
end

---@param buf integer
local function enabled(buf)
  local override = vim.b[buf].format_on_save
  if override ~= nil then
    return override
  end
  return state.on_save
end

--- Toggles format on save for the current buffer, whether it came from `on_save` or from
--- `vim.b.format_on_save` set in an ftplugin. With `global`, toggles `on_save` for every buffer
--- instead, except those that set `vim.b.format_on_save`.
---@param global? boolean
function M.toggle_on_save(global)
  if not state.ready then
    vim.notify("batu: format is not set up", vim.log.levels.WARN)
    return
  end

  if global then
    state.on_save = not state.on_save
    vim.notify("batu: format on save " .. (state.on_save and "on" or "off") .. " globally")
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local on = not enabled(buf)
  vim.b[buf].format_on_save = on
  vim.notify("batu: format on save " .. (on and "on" or "off") .. " for this buffer")
end

---@param opts? batu.FormatConfig
function M.setup(opts)
  opts = opts or {}
  state.on_save = opts.on_save or false
  state.timeout_ms = opts.timeout_ms or 1000
  state.ready = true

  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("batu.format", { clear = true }),
    desc = "Format the buffer before writing it",
    callback = function(args)
      -- Skip special buffers, and URL-style ones such as oil:// or scp://.
      if vim.bo[args.buf].buftype ~= "" or not vim.bo[args.buf].modifiable or args.match:match("^%w%w+:[\\/][\\/]") then
        return
      end
      if enabled(args.buf) then
        M.format(args.buf)
      end
    end,
  })
end

return M
