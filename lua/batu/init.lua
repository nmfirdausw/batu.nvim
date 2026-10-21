local M = {}

---@class batu.Config
---@field options boolean|table<string, any> `true` applies Batu's defaults, `false` applies none,
---  a table applies the defaults with your values merged on top.
---@field keymaps boolean|table<string, table<string, batu.Keymap>> `true` applies Batu's default keymaps,
---  `false` applies none, a table applies them and also your own, per mode and key: `false` skips a
---  default, a string, function or `{ rhs, desc = ... }` table sets (or replaces) a keymap.
---@field autocmds boolean|table<string, boolean> `true` creates Batu's default autocmds, `false`
---  creates none, a table creates them except those set to `false`, by name.
---@field diagnostic boolean|vim.diagnostic.Opts `true` applies Batu's diagnostic defaults, `false` leaves
---  Neovim's alone, a table applies the defaults with your `vim.diagnostic.config()` values merged on top.
---@field completion boolean|batu.CompletionConfig `true` uses Neovim's built-in completion, opened on
---  request (`<C-x><C-o>`, `<C-n>`, `<C-p>`, and `<Tab>` on the command line), `false` leaves completion
---  alone, a table sets `autoshow = true` to open the menu as you type, `documentation = true` and
---  `signature_help = true` to show item documentation and signature help, and `blink = true` (or a table of
---  blink.cmp options) to use blink.cmp instead.
---@field format boolean|batu.FormatConfig `true` (default) sets up formatting: `<leader>cf` formats the buffer
---  and `<leader>tf` toggles format on save, which is off unless a table sets `on_save = true`. `false`
---  leaves formatting alone.
---@field find boolean `true` (default) makes `:find` fuzzy search every file under the cwd. `false` leaves
---  `:find` alone.
---@field lsp false|batu.LspConfig `false` does nothing, a table enables your language `servers`.
---@field leader string|false The key used for `<leader>` and `<localleader>`, unless you already set
---  `vim.g.mapleader` or `vim.g.maplocalleader`. `false` leaves them alone.
---@field osc7 boolean `true` syncs Neovim's cwd to the directory the terminal reports via OSC 7.
local defaults = {
  leader = " ",
  options = true,
  keymaps = true,
  autocmds = true,
  diagnostic = true,
  completion = true,
  format = true,
  find = true,
  lsp = false,
  osc7 = false,
}

---@param opts? batu.Config
function M.setup(opts)
  local config = vim.tbl_extend("force", defaults, opts or {})

  -- Mappings expand <leader> when they are defined, so this has to come first.
  if config.leader then
    vim.g.mapleader = vim.g.mapleader or config.leader
    vim.g.maplocalleader = vim.g.maplocalleader or config.leader
  end

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

  if config.autocmds then
    require("batu.autocmds").setup(type(config.autocmds) == "table" and config.autocmds or nil)
  end

  if config.diagnostic then
    require("batu.diagnostic").setup(type(config.diagnostic) == "table" and config.diagnostic or nil)
  end

  -- Before lsp, so blink's capabilities are in place when servers are enabled.
  if config.completion then
    require("batu.completion").setup(type(config.completion) == "table" and config.completion or nil)
  end

  if config.format then
    require("batu.format").setup(type(config.format) == "table" and config.format or nil)
  end

  if config.find then
    require("batu.find").setup()
  end

  if config.lsp then
    require("batu.lsp").setup(config.lsp)
  end

  if config.osc7 then
    require("batu.osc7").setup()
  end
end

return M
