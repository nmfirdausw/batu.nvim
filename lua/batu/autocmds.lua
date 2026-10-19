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
