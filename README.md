# 🪨 batu.nvim

> **Simple by nature. Refined by design.**
>
> A modern Neovim editor built on thoughtful defaults.

---

## What is batu.nvim?

Neovim is already one of the finest text editors ever created.

**batu.nvim** doesn't try to replace it.

Instead, it refines the experience through careful craftsmanship, sensible defaults, and modern design—without hiding the editor you already know and love.

Install it like any other plugin.

Keep your own configuration.

Customize only when you need to.

No starter repository.

No framework.

No unnecessary abstraction.

Just Neovim, thoughtfully refined.

---

# Why Batu?

A stone begins as something ordinary.

With time, intention, and craftsmanship, it becomes something enduring.

Some become the foundation of great architecture.

Others become sculptures.

Others become precious gemstones.

The value isn't found in complexity—it is found in refinement.

**batu.nvim** follows the same philosophy.

Neovim is already an exceptional foundation.

Rather than rebuilding it from scratch, Batu carefully refines the experience while preserving what makes Neovim great.

Every feature exists for a reason.

Every default has a purpose.

Nothing is added simply because everyone else has it.

---

# Philosophy

## Simplicity over complexity

Good defaults should remove decisions, not create more of them.

Install Batu and start editing.

Configure only what matters to you.

---

## Native before dependencies

Neovim already provides an incredible foundation.

Whenever possible, Batu embraces native functionality first and adds plugins only when they provide genuine value.

Dependencies should enhance the editor—not define it.

---

## Thoughtful craftsmanship

Every detail matters.

Spacing.

Typography.

Highlights.

Statusline.

Statuscolumn.

Tabline.

Window layout.

Nothing exists by accident.

A polished editor is the result of hundreds of small decisions.

---

## Modern without excess

Modern doesn't mean filling every corner of the screen.

It means creating an interface that feels calm, predictable, and enjoyable to use.

Minimal doesn't mean empty.

It means intentional.

---

## Your editor remains yours

Most Neovim distributions ask you to replace your configuration.

Batu doesn't.

Your init.lua stays yours.

Your plugins stay yours.

Your workflow stays yours.

Batu simply provides a carefully designed editor experience that integrates naturally into your configuration.

---

# Principles

- 🪨 Thoughtful defaults
- 🌿 Native-first design
- 🧩 Modular architecture
- ✨ Beautiful without distraction
- 🖱️ Mouse-friendly where it improves usability
- 📦 Installable like a plugin
- 🔧 Easy to understand
- 🚀 Easy to extend

---

# What Batu is

- A modern Neovim editor
- A refined editing experience
- A carefully designed set of defaults
- A polished user interface
- A solid foundation for your own workflow

---

# What Batu is not

- An IDE
- A starter configuration
- A plugin bundle
- A framework that owns your configuration

---

# Installation

Requires Neovim with `vim.pack` (0.12+).

Add Batu to your `init.lua`:

```lua
vim.pack.add({ "https://github.com/nmfirdausw/batu.nvim" })

require("batu").setup()
```

That's it.

No templates.

No migration guides.

No replacing your ~/.config/nvim.

Just install, configure, and start editing.

## Configuration

`setup()` applies Batu's defaults. Pass options only for what you want to change:

```lua
require("batu").setup({
  options = {
    shiftwidth = 2,
    tabstop = 2,
    softtabstop = 2,
  },
})
```

`options` accepts:

- `true` (default): apply Batu's defaults
- `false`: apply none
- a table: apply the defaults with your values merged on top

`keymaps` accepts:

- `true` (default): apply Batu's default keymaps
- `false`: apply none
- a table: apply the defaults, plus your own and changes to them, per mode and key

Each value is one of:

- `false`: skip a Batu keymap
- a string or function: set (or replace) the keymap's right-hand side
- a table `{ rhs, desc = "...", ... }`: the same, with any `vim.keymap.set` option

```lua
require("batu").setup({
  keymaps = {
    x = { [">"] = false },                              -- skip a default
    n = {
      ["<leader>w"] = { "<cmd>write<CR>", desc = "Save" }, -- add your own
    },
  },
})
```

Available keymaps:

| Mode    | Key              | Action                                                    |
| ------- | ---------------- | --------------------------------------------------------- |
| `x`     | `<`              | Shift left, keeping the visual selection                  |
| `x`     | `>`              | Shift right, keeping the visual selection                 |
| `n`, `x` | `j`, `<Down>`   | Move down by visual line when wrapped, by count otherwise |
| `n`, `x` | `k`, `<Up>`     | Move up by visual line when wrapped, by count otherwise   |

`osc7` accepts:

- `false` (default): do nothing
- `true`: sync Neovim's working directory to the directory your terminal reports via OSC 7 (`:terminal` buffers)

---

# The Vision

There are countless Neovim configurations.

There are countless plugin collections.

Batu aims to be something different.

Not another configuration.

Not another framework.

But a thoughtfully crafted editor experience that feels complete from the very first launch, while remaining unmistakably Neovim.

---

> **Simple by nature. Refined by design.**

Build on stone.
