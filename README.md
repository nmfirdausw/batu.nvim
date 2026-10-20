# 🪨 batu.nvim

> **Simple by nature. Refined by design.**

A modern Neovim editor built on thoughtful defaults.

Batu doesn't replace Neovim. It refines it with sensible defaults and a calm interface, and it leaves the editor you know in place. Install it like any plugin and keep your own config. There's no starter repo and no framework.

A stone becomes something lasting through intention and craftsmanship, not complexity. Batu follows the same idea: every feature has a reason, and nothing is added just because everyone else has it.

## Philosophy

- **Simplicity over complexity.** Good defaults remove decisions. Install, start editing, and configure only what matters to you.
- **Native before dependencies.** Batu uses what Neovim already provides and adds a plugin only when it earns its place.
- **Thoughtful craftsmanship.** Statusline, statuscolumn, tabline, highlights and window layout are all deliberate choices.
- **Modern without excess.** Minimal means intentional, not empty.
- **Your editor stays yours.** Your `init.lua`, plugins and workflow are untouched.

**Batu is** a refined set of defaults and a solid base for your own workflow.
**Batu is not** an IDE, a starter config, a plugin bundle, or a framework that owns your configuration.

## Install

Requires Neovim 0.12+ (`vim.pack`).

```lua
vim.pack.add({ "https://github.com/nmfirdausw/batu.nvim" })

require("batu").setup()
```

## Configure

Every key is optional. Pass only what you want to change.

```lua
require("batu").setup({
  leader = ",",
  options = { shiftwidth = 2, tabstop = 2, softtabstop = 2 },
  keymaps = {
    x = { [">"] = false },                                -- skip a default
    n = { ["<leader>w"] = { "<cmd>write<CR>", desc = "Save" } }, -- add your own
  },
  autocmds = { highlight_yank = false },
  lsp = { servers = { lua_ls = true }, inlay_hints = true },
  osc7 = true,
})
```

| Key        | Default | Values                                                         |
| ---------- | ------- | -------------------------------------------------------------- |
| `options`  | `true`  | `false` for none, or a table merged over the defaults          |
| `leader`   | `" "`   | another key, or `false` to leave it alone                      |
| `keymaps`  | `true`  | `false` for none, or a table by mode and key (see below)       |
| `autocmds` | `true`  | `false` for none, or a table of `name = false` to disable      |
| `diagnostic` | `true` | `false` to leave Neovim's alone, or a `vim.diagnostic.config()` table merged over the defaults |
| `completion` | `true` | `false` to leave completion alone |
| `lsp`      | `false` | a table, see [LSP](#lsp)                                       |
| `osc7`     | `false` | `true` to sync the cwd with the terminal's OSC 7 (`:terminal`) |

An existing `vim.g.mapleader` is never overridden. Set the leader before any `<leader>` mappings.

## Keymaps

Each entry is `false` (skip), a string or function (set or replace), or `{ rhs, desc = "...", ... }` with any `vim.keymap.set` option.

| Mode    | Key                  | Action                                                |
| ------- | -------------------- | ----------------------------------------------------- |
| `x`     | `<` `>`              | Shift, keeping the selection                          |
| `x`     | `p`                  | Paste without overwriting the register                |
| `x`     | `J` `K`              | Move selected lines down or up                        |
| `n`     | `Y`                  | Yank to end of line                                   |
| `n`     | `<C-d>` `<C-u>`      | Half-page scroll, cursor centered                     |
| `n`     | `n` `N`              | Next or previous match, centered                      |
| `n`     | `<C-w>d`             | Diagnostic float of the line, hiding inline text      |
| `n`     | `<leader>dv`         | Toggle diagnostic virtual text/lines                  |
| `n`     | `<leader>dt`         | Toggle diagnostics                                    |
| `n`     | `<leader>dl` `<leader>dq` | Diagnostics to location list / quickfix          |
| `n` `x` | `j` `k` (and arrows) | Visual-line movement when wrapped, by count otherwise |

## Autocmds

| Name              | Action                                                 |
| ----------------- | ------------------------------------------------------ |
| `highlight_yank`  | Briefly highlight yanked text                          |
| `restore_cursor`  | Restore the last cursor position on reopen             |
| `auto_create_dir` | Create missing parent directories on write             |
| `auto_reload`     | Reload buffers changed on disk                         |
| `close_with_q`    | Close help, quickfix, man and similar buffers with `q` |

## Diagnostics

Defaults: `severity_sort`, `update_in_insert` and `virtual_text` on. Pass a table to change them, for example `diagnostic = { update_in_insert = false }`.

## Completion

By default Batu uses Neovim's built-in completion: the command-line menu opens as you type, and LSP completion triggers on every letter, digit and `_` instead of only after `.` or `:`. `completion = false` leaves completion untouched.

## LSP

Batu doesn't install servers. It uses `vim.lsp.config()` and `vim.lsp.enable()`. Server configs come from one of two places.

**nvim-lspconfig** (Batu installs and loads it):

```lua
lsp = {
  lspconfig = true,
  servers = {
    lua_ls = true,                                             -- use lspconfig's config
    gopls = { settings = { gopls = { staticcheck = true } } }, -- merge on top
    pyright = false,                                           -- skip
  },
}
```

**Your own** `~/.config/nvim/lsp/<name>.lua`, then `lsp = { servers = { lua_ls = true } }`.

| Option        | Default | Description                                          |
| ------------- | ------- | ---------------------------------------------------- |
| `inlay_hints` | `false` | Enable inlay hints where the server supports them    |
| `codelens`    | `false` | Enable code lenses where the server supports them    |
| `keymaps`     | `true`  | `grh` toggles inlay hints, `grl` toggles code lenses |

Neovim's built-in LSP maps (`grn`, `gra`, `grr`, `gri`, `grt`, `grx`, `gO`, `K`) work as usual.

---

*Build on stone.*
