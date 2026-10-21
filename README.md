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
| `completion` | `true` | `{ blink = true }` for [blink.cmp](https://github.com/saghen/blink.cmp), or `false` to leave it alone |
| `format`   | `true`  | `false` to leave it alone, or `{ on_save = true, timeout_ms = 1000 }` |
| `find`     | `true`  | `{ fff = true }` to search with [fff](https://github.com/dmtrKovalenko/fff), or `false` to leave `:find` alone |
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
| `n` `x` | `<leader>cf`         | Format the buffer, or the selection                   |
| `n` `x` | `gq` `gqq`           | Format, keeping the text when the formatter fails     |
| `n`     | `<leader>tf` `<leader>tF` | Toggle format on save for the buffer / globally  |
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

## Format

Batu formats with Neovim's own settings, so it follows what `gq` does. By default that is the language server (`vim.lsp.formatexpr`). To use an external formatter for a filetype, set `formatprg` in `ftplugin/<ft>.lua`. It wins over the language server, even though the server attaches later:

```lua
vim.opt_local.formatprg = "stylua --indent-type Spaces --indent-width 2 --quote-style AutoPreferDouble -"
```

`<leader>cf` formats the buffer (or the selection in visual mode). `gq` itself is wrapped too, so a failing `formatprg` or custom `formatexpr` keeps your text instead of replacing it with the error. Everything else is Neovim's own `gq`. Format on save is off by default: turn it on with `format = { on_save = true }`, or toggle it with `<leader>tF` for every buffer, or `<leader>tf` for the current buffer only, which works whether it was turned on by `on_save` or by an ftplugin. A buffer's own setting wins over the global one. `<leader>tf` sets `vim.b.format_on_save` for the buffer, and you can set it to `true` or `false` yourself too. To format on save for one filetype only, leave `on_save` off and set it in that filetype's `ftplugin/<ft>.lua`:

```lua
vim.b.format_on_save = true
```

The other way round works too: keep `on_save = true` and set `vim.b.format_on_save = false` in the ftplugins of the filetypes to skip. `timeout_ms` (default 1000) limits how long a language server may take to format on save. A failing `formatprg` leaves the buffer unchanged. `format = false` leaves formatting alone.

## Find

`:find` fuzzy searches every file under the current directory, instead of matching a path pattern. `:find cfgld` opens `src/deep/config_loader.lua`, and completing it (`<Tab>`, or the menu with `autoshow`) lists the fuzzy matches, best first. The file list comes from `rg`, `fd` or `git ls-files` when one is installed, so ignored files and `.git` are skipped, and from a plain walk of the directory otherwise (skipping only `.git`). It is built once per command line, so new files appear the next time. `find = false` leaves `:find` alone.

Use `find = { fff = true }` to search with [fff](https://github.com/dmtrKovalenko/fff) instead. Batu installs it with `vim.pack`, downloads its prebuilt binary (or builds it with `cargo`), and calls `require("fff").file_search()` for `:find` and its completion. fff keeps its own index of the cwd, is typo-resistant, ranks the files you open often higher, and understands constraints such as `*.lua` or `git:modified`. Pass a table, `find = { fff = { max_threads = 8 } }`, to give fff its own options. While fff is still indexing the cwd, or if it fails, the search above answers instead.

## Completion

By default Batu uses Neovim's built-in completion, and the menu never opens by itself. Open it with `<C-x><C-o>` (LSP omni completion), `<C-n>` or `<C-p>`, or `<Tab>` on the command line. Set `completion = { autoshow = true }` to open the menu as you type instead: on the command line, and in LSP completion, which then triggers on every letter, digit and `_` rather than only after `.` or `:`.

Documentation and signature help are off by default. Set `completion = { documentation = true }` to show the documentation of the selected item next to the menu, and `completion = { signature_help = true }` to show the signature help when you type a call's `(` or `,`. Both work with either engine. In insert mode, `<C-k>` toggles the signature help and `<C-b>` / `<C-f>` scroll the documentation, the same keys blink.cmp uses.

Use `completion = { blink = true }` to install and set up blink.cmp (v2) instead; it follows the same `autoshow` setting, and `<C-n>`/`<C-p>` open its menu too. Nothing is preselected, and `<CR>` accepts the selected item (or acts as usual when none is selected). Pass a table, `completion = { blink = { keymap = { preset = "super-tab" } } }`, to give blink its own options, which are merged over Batu's. `completion = false` leaves completion untouched.

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
