local M = {}

---@type vim.diagnostic.Opts
local defaults = {
  severity_sort = true,
  update_in_insert = true,
  virtual_text = true,
}

---@param opts? vim.diagnostic.Opts overrides merged on top of the defaults
function M.setup(opts)
  vim.diagnostic.config(vim.tbl_deep_extend("force", defaults, opts or {}))
end

return M
