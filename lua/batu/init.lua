local M = {}

---@class batu.Config
---@field options boolean|table<string, any> `true` applies Batu's defaults, `false` applies none,
---  a table applies the defaults with your values merged on top.
---@field osc7 boolean `true` syncs Neovim's cwd to the directory the terminal reports via OSC 7.
local defaults = {
  options = true,
  osc7 = false,
}

---@param opts? batu.Config
function M.setup(opts)
  local config = vim.tbl_extend("force", defaults, opts or {})

  if config.options then
    local options = vim.deepcopy(require("batu.options"))
    if type(config.options) == "table" then
      options = vim.tbl_extend("force", options, config.options)
    end
    for name, value in pairs(options) do
      vim.opt[name] = value
    end
  end

  if config.osc7 then
    require("batu.osc7").setup()
  end
end

return M
