local M = {}

---@type table<string, {[1]: string|string[], [2]: vim.api.keyset.create_autocmd}>
local defaults = {
  -- Briefly highlight yanked text
  highlight_yank = {
    "TextYankPost",
    {
      desc = "Briefly highlight yanked text",
      callback = function()
        vim.hl.hl_op()
      end,
    },
  },
  -- Restore cursor to last known position when reopening a file
  restore_cursor = {
    "BufReadPost",
    {
      desc = "Restore cursor to last known position when reopening a file",
      callback = function(args)
        local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
        local line_count = vim.api.nvim_buf_line_count(args.buf)
        if mark[1] > 0 and mark[1] <= line_count then
          vim.api.nvim_win_set_cursor(0, mark)
        end
      end,
    },
  },
  -- Create missing parent directories before writing a file
  auto_create_dir = {
    "BufWritePre",
    {
      desc = "Create missing parent directories before writing a file",
      callback = function(args)
        -- Skip URL-style buffers such as oil:// or scp://
        if args.match:match("^%w%w+:[\\/][\\/]") then
          return
        end
        vim.fn.mkdir(vim.fn.fnamemodify(args.match, ":p:h"), "p")
      end,
    },
  },
  -- Reload buffers changed on disk outside of Neovim
  auto_reload = {
    { "FocusGained", "BufEnter" },
    {
      desc = "Reload buffers changed on disk outside of Neovim",
      command = "checktime",
    },
  },
  -- Close utility/read-only buffers with q
  close_with_q = {
    "FileType",
    {
      desc = "Close utility/read-only buffers with q",
      pattern = { "help", "qf", "man", "lspinfo", "checkhealth" },
      callback = function(args)
        vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = args.buf, silent = true, desc = "Close window" })
      end,
    },
  },
}

---@param overrides? table<string, boolean> autocmds by name, `false` skips one
function M.setup(overrides)
  overrides = overrides or {}
  local group = vim.api.nvim_create_augroup("batu.autocmds", { clear = true })

  for name, autocmd in pairs(defaults) do
    if overrides[name] ~= false then
      local opts = vim.tbl_extend("force", autocmd[2], { group = group })
      vim.api.nvim_create_autocmd(autocmd[1], opts)
    end
  end

  for name in pairs(overrides) do
    if defaults[name] == nil then
      vim.notify(("batu: unknown autocmd %s"):format(name), vim.log.levels.WARN)
    end
  end
end

return M
