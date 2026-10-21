local M = {}

---@type { cwd: string, files: string[] }?
local cache

--- Every file under the cwd, ignoring `.git` and what your ignore files list when a tool that knows
--- them is installed.
---@return string[]
local function list_files()
  local commands = {
    { "rg", "--files", "--hidden", "--glob", "!.git" },
    { "fd", "--type", "file", "--hidden", "--exclude", ".git" },
    { "git", "ls-files", "--cached", "--others", "--exclude-standard" },
  }

  for _, cmd in ipairs(commands) do
    if vim.fn.executable(cmd[1]) == 1 then
      local result = vim.system(cmd, { text = true }):wait()
      if result.code == 0 then
        return vim.split(result.stdout or "", "\n", { trimempty = true })
      end
    end
  end

  local files = {}
  for path, kind in vim.fs.dir(".", { depth = math.huge, skip = function(dir) return dir ~= ".git" end }) do
    if kind == "file" then
      table.insert(files, path)
    end
  end
  return files
end

---@return string[]
local function files()
  local cwd = vim.uv.cwd() or ""
  if not cache or cache.cwd ~= cwd then
    cache = { cwd = cwd, files = list_files() }
  end
  return cache.files
end

--- 'findfunc': fuzzy matches the files under the cwd, best first.
---@param cmdarg string
---@return string[]
function M.findfunc(cmdarg)
  if cmdarg == "" then
    return files()
  end
  return vim.fn.matchfuzzy(files(), cmdarg)
end

function M.setup()
  vim.o.findfunc = "v:lua.require'batu.find'.findfunc"

  -- The list is built once per command line, so files you create or delete show up the next time.
  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = vim.api.nvim_create_augroup("batu.find", { clear = true }),
    desc = "Forget the cached file list for :find",
    callback = function()
      cache = nil
    end,
  })
end

return M
