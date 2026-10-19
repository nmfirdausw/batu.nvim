local M = {}

---@alias batu.Keymap false|string|function|table `false` skips the keymap, a string or function sets its
---  right-hand side, a table sets `{ rhs, desc = ..., ... }` with any `vim.keymap.set` option.

---@type table<string, table<string, {[1]: string|function, [2]: table}>>
local defaults = {
  x = {
    -- Keep in visual mode while indenting
    ["<"] = { "<gv", { desc = "Shift left" } },
    [">"] = { ">gv", { desc = "Shift right" } },
  },
}

---@param value string|function|table
---@param default? {[1]: string|function, [2]: table}
---@return string|function|nil rhs
---@return table opts
local function resolve(value, default)
  local rhs, opts = default and default[1], default and default[2] or {}
  if type(value) == "table" then
    opts = vim.tbl_extend("force", opts, value)
    rhs = opts[1] or rhs
    opts[1] = nil
  else
    rhs = value
  end
  return rhs, opts
end

---@param overrides? table<string, table<string, batu.Keymap>> keymaps per mode, per key
function M.setup(overrides)
  overrides = overrides or {}

  for mode, maps in pairs(defaults) do
    for lhs, default in pairs(maps) do
      if (overrides[mode] or {})[lhs] == nil then
        vim.keymap.set(mode, lhs, default[1], default[2])
      end
    end
  end

  for mode, maps in pairs(overrides) do
    for lhs, value in pairs(maps) do
      if value ~= false then
        local rhs, opts = resolve(value, (defaults[mode] or {})[lhs])
        if rhs then
          vim.keymap.set(mode, lhs, rhs, opts)
        else
          vim.notify(("batu: keymap %s %s has no right-hand side"):format(mode, lhs), vim.log.levels.WARN)
        end
      end
    end
  end
end

return M
