local M = {}

---@class batu.FindConfig
---@field fff? boolean|table `true` installs fff (via `vim.pack`) and uses it to search, a table does the
---  same with your `fff` options. `false` (default) searches with `rg`, `fd` or `git ls-files`.

---@type boolean whether `:find` is searched with fff
local use_fff = false

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

---@param cmdarg string
---@return string[]? paths nil until fff has indexed the cwd, or when it failed
local function fff_files(cmdarg)
  local ok, result = pcall(function()
    -- Never block on an index scan, the file list below answers until it is done.
    local found = require("fff").file_search(cmdarg, { cwd = vim.uv.cwd(), wait_for_index_ms = 0 })
    if #found.items > 0 and require("fff.fuzzy").get_scan_progress().is_index_ready then
      return vim.tbl_map(function(item)
        return item.relative_path
      end, found.items)
    end
  end)
  return ok and result or nil
end

--- 'findfunc': fuzzy matches the files under the cwd, best first.
---@param cmdarg string
---@return string[]
function M.findfunc(cmdarg)
  if use_fff then
    local paths = fff_files(cmdarg)
    if paths then
      return paths
    end
  end
  if cmdarg == "" then
    return files()
  end
  return vim.fn.matchfuzzy(files(), cmdarg)
end

---@param opts? table fff options
local function fff(opts)
  -- Registered before `vim.pack.add()`, so it also runs for the first install.
  vim.api.nvim_create_autocmd("PackChanged", {
    group = vim.api.nvim_create_augroup("batu.find.fff", { clear = true }),
    desc = "Download or build fff's binary",
    callback = function(ev)
      local data = ev.data
      if data.spec.name == "fff" and (data.kind == "install" or data.kind == "update") then
        if not data.active then
          vim.cmd.packadd("fff")
        end
        require("fff.download").download_or_build_binary()
      end
    end,
  })

  vim.pack.add({ "https://github.com/dmtrKovalenko/fff" })
  require("fff").setup(opts or {})
  use_fff = true

end

---@param opts? batu.FindConfig
function M.setup(opts)
  local engine = opts and opts.fff
  if engine then
    fff(type(engine) == "table" and engine or nil)
  end

  vim.opt.findfunc = "v:lua.require'batu.find'.findfunc"

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
