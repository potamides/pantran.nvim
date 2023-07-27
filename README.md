<!-- panvimdoc-ignore-start -->
# Pantran.nvim
[![tests](https://github.com/potamides/pantran.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/potamides/pantran.nvim/actions)
[![versions](https://img.shields.io/badge/Neovim-v0.6.1%2B-informational?logo=neovim&logoColor=inactive)](https://github.com/neovim/neovim/wiki/Installing-Neovim)
<!-- panvimdoc-ignore-end -->
With pantran.nvim, you can use your favorite machine translation engines
without having to leave your favorite editor. It makes use of Neovim's
[api-floatwin](https://neovim.io/doc/user/api.html#api-floatwin) to implement
an asynchronous, interactive machine translation interface, similar to how
most of the various machine translation web front-ends work. In addition to
that, other (non-interactive) modes are also supported and, if you try hard
enough, pantran.nvim can also be used as an API.

<!-- panvimdoc-ignore-start -->
[Pantran.nvim demonstration](https://user-images.githubusercontent.com/53401822/177125473-572c8ebf-fd5c-448f-827c-f6992e24bb02.mp4)

**Warning**: This is beta quality software. It should run stable for the most
part, but don't be too surprised if you find a few bugs here and there. Use at
your own risk!

# Installation
You need at least [Neovim v0.6.1](https://neovim.io/) and
[curl v7.76.0](https://curl.se/) to be able to use this plugin. You can
install it using your favorite plugin manager.

With [vim-plug](https://github.com/junegunn/vim-plug):
```viml
Plug "potamides/pantran.nvim"
```

With [dein](https://github.com/Shougo/dein.vim):
```viml
call dein#add("potamides/pantran.nvim")
```

With [packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use {
  "potamides/pantran.nvim"
}
```
<!-- panvimdoc-ignore-end -->

# Quickstart
Run the command `:Pantran` to open an interactive translation window and start
typing to get an understanding of how things work. Type `g?` in normal mode or
`i_CTRL-/` in insert mode to open a help buffer with available keybindings.
`:Pantran` also supports command ranges to initialize the translation window.
Further, some optional flags for configuration of the translation process are
available<!-- panvimdoc-ignore-start -->, consult the
[documentation](doc/README.md) for more details<!-- panvimdoc-ignore-end -->.
If you plan to translate frequently, the command can also be mapped to the
following recommended keybindings:

<!-- panvimdoc-ignore-start -->
<details open>
<!-- panvimdoc-ignore-end -->
<summary>Neovim 0.7+</summary>

```lua
local opts = {noremap = true, silent = true, expr = true}
vim.keymap.set("n", "<leader>tr", pantran.motion_translate, opts)
vim.keymap.set("n", "<leader>trr", function() return pantran.motion_translate() .. "_" end, opts)
vim.keymap.set("x", "<leader>tr", pantran.motion_translate, opts)
```

</details>
<details><summary>Neovim 0.6</summary>

```lua
local opts = {noremap = true, silent = true, expr = true}
vim.api.nvim_set_keymap("n", "<leader>tr", [[luaeval("require('pantran').motion_translate()")]], opts)
vim.api.nvim_set_keymap("n", "<leader>trr", [[luaeval("require('pantran').motion_translate() .. '_'")]], opts)
vim.api.nvim_set_keymap("x", "<leader>tr", [[luaeval("require('pantran').motion_translate()")]], opts)
```

</details>

The mappings work similarly to the command in that they also allow you to use
ranges. E.g., you can use `3<leader>trr` to populate the translation window
with the next three lines of text. One advantage over the command, however, is
the additional support for [text
objects](https://neovim.io/doc/user/motion.html#text-objects). You can use
`<leader>tris` or `<leader>trip` to translate the surrounding sentence or
paragraph, for example. Other translation modes like replacing or appending
text immediately without opening an interactive window are also
implemented.<!-- panvimdoc-ignore-start --> Again, consult the
[documentation](doc/README.md) for more details.<!-- panvimdoc-ignore-end -->

# Scope
The plugin already supports a few different translation engines. If
you have any further suggestions feel free to open an
[issue](https://github.com/potamides/pantran.nvim/issues) or [pull
request](https://github.com/potamides/pantran.nvim/pulls)! The currently
supported engines are as follows:

* [Apertium](https://apertium.org)
* [Argos Translate](https://translate.argosopentech.com)
* [DeepL](https://www.deepl.com/translator)
* [Google Translate](https://translate.google.com)
* [Yandex Translate](https://translate.yandex.com)

Some of these engines are free and open-source and can be used right off the
bat. However, some are commercial and might require additional setup steps.
For stability reasons, the philosophy of this plugin is to prioritize official
API endpoints for which commercial engines usually require some means of
authentication, e.g., through an API key. If no such key is configured but
free alternative endpoints exist, these are used as fallback options. Note,
however, that these are often [severely
rate-limited](https://github.com/soimort/translate-shell/issues/370) and in
some instances produce [inferior
translations](https://github.com/Animenosekai/translate/issues/22). So if you
want to use a commercial engine, configuring authentication is usually
recommended<!-- panvimdoc-ignore-start --> (see the [docs](doc/README.md) for
more information)<!-- panvimdoc-ignore-end -->.

<!-- panvimdoc-ignore-start -->
# Configuration
Pantran.nvim supports a wide range of configuration options. Some essential
ones are listed below, for a full list consult the additional
[documentation](doc/README.md). The invocation of `require("pantran").setup()`
is optional.

```lua
require("pantran").setup{
  -- Default engine to use for translation. To list valid engine names run
  -- `:lua =vim.tbl_keys(require("pantran.engines"))`.
  default_engine = "argos",
  -- Configuration for individual engines goes here.
  engines = {
    yandex = {
      -- Default languages can be defined on a per engine basis. In this case
      -- `:lua require("pantran.async").run(function()
      -- vim.pretty_print(require("pantran.engines").yandex:languages()) end)`
      -- can be used to list available language identifiers.
      default_source = "auto",
      default_target = "en"
    },
  },
  controls = {
    mappings = {
      edit = {
        n = {
          -- Use this table to add additional mappings for the normal mode in
          -- the translation window. Either strings or function references are
          -- supported.
          ["j"] = "gj",
          ["k"] = "gk"
        },
        i = {
          -- Similar table but for insert mode. Using 'false' disables
          -- existing keybindings.
          ["<C-y>"] = false,
          ["<C-a>"] = require("pantran.ui.actions").yank_close_translation
        }
      },
      -- Keybindings here are used in the selection window.
      select = {
        n = {
          -- ...
        }
      }
    }
  }
}
```
<!-- panvimdoc-ignore-end -->

<!-- vim: set textwidth=78: -->
