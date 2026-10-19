local M = {}

function M.setup()
  vim.api.nvim_create_autocmd("TermRequest", {
    group = vim.api.nvim_create_augroup("batu.osc7", { clear = true }),
    desc = "Sync Neovim's cwd to the terminal's OSC 7 reported directory",
    callback = function(args)
      local seq = args.data.sequence
      local dir = seq and seq:match("^\027]7;file://[^/]*(.+)")
      if dir then
        vim.fn.chdir(vim.uri_decode(dir))
      end
    end,
  })
end

return M
