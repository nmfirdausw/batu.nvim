return {
  -- editing
  expandtab = true,
  shiftround = true,
  shiftwidth = 4,
  smartindent = true,
  softtabstop = 4,
  tabstop = 4,
  virtualedit = "block",

  -- behaviour
  clipboard = "unnamedplus",
  confirm = true,
  timeoutlen = 300,
  undofile = true,
  updatetime = 250,

  -- interface
  cmdheight = 0,
  cursorline = true,
  cursorlineopt = "number",
  laststatus = 3,
  list = true,
  listchars = { tab = "» ", trail = "·", nbsp = "␣" },
  number = true,
  pumheight = 10,
  relativenumber = true,
  scrolloff = 8,
  sidescrolloff = 8,
  signcolumn = "yes",
  splitbelow = true,
  splitright = true,

  -- search
  ignorecase = true,
  inccommand = "split",
  smartcase = true,

  -- completion
  completeopt = "menuone,noselect",
  wildignorecase = true,
  wildmode = "noselect:lastused,full",

  -- folding
  foldexpr = "v:lua.vim.treesitter.foldexpr()",
  foldlevelstart = 99,
  foldmethod = "expr",
}
