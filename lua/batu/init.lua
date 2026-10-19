local M = {}

---@class batu.Config
---@field options boolean|table<string, any> `true` applies Batu's defaults, `false` applies none,
---  a table applies the defaults with your values merged on top.
---@field keymaps boolean|table<string, table<string, batu.Keymap>> `true` applies Batu's default keymaps,
---  `false` applies none, a table applies them and also your own, per mode and key: `false` skips a
---  default, a string, function or `{ rhs, desc = ... }` table sets (or replaces) a keymap.
---@field osc7 boolean `true` syncs Neovim's cwd to the directory the terminal reports via OSC 7.
local defaults = {
  options = true,
  keymaps = true,
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

  if config.keymaps then
    require("batu.keymaps").setup(type(config.keymaps) == "table" and config.keymaps or nil)
  end

  if config.osc7 then
    require("batu.osc7").setup()
  end
end

return M
