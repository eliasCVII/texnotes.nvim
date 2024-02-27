# texnotes.nvim
This is a wip.
A neovim plugin to improve the workflow for [TeXNotes](https://github.com/alfredholmes/TeXNotes)
## Requirements
- `fd` for windows, it works on linux as well.
- `mini.pick`
## features
- Auto-compiling on save, can be disabled
- Open up your compiled files right away
- Create, delete, rename your notes all in one place.
## Installation
Install texnotes.nvim with your preferred plugin manager, for example with [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "eliasCVII/texnotes.nvim",
    event = "VeryLazy",
    dependencies = {
        "nvim-lua/plenary.nvim",
        {'echasnovski/mini.pick', version = false},
    }
    opts = {
        path = "~/notes/texnotes",
        compile_on_write = true,
    },
}
```

## Configuration
```lua
require("texnotes").setup({
    path = "/path/to/your/texnotes/folder",
    compile_on_write = true,
    render_format = "pdf",
})
```
## Autocompletion
This plugin includes a nvim-cmp source that helps you with labels and references
## TODO: Usage
### Commands
