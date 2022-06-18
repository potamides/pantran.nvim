# Perapera
Perapera is here to help you use your favorite machine translation engines
without having to leave your favorite editor. The main focus is on
asynchronous, interactive machine translation, similar to what you know from
various web front-ends, but some non-interactive modes are also supported. If
you try hard enough it can also be used as an API.

<p align="center">
  <img src="https://media.giphy.com/media/9AIdwhAnzTb7AqHYeC/giphy.gif" alt="Perapera Demonstration"/>
</p>

## Installation
You need at least [Neovim v0.6+](https://neovim.io/) and
[curl](https://curl.se/) to be able to use this plugin. Install it using your
favorite plugin manager.

Using [vim-plug](https://github.com/junegunn/vim-plug)
```viml
Plug "potamides/peraperea.nvim"
```

Using [dein](https://github.com/Shougo/dein.vim)
```viml
call dein#add("potamides/peraperea.nvim")
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use {
  "potamides/peraperea.nvim",
}
```

## Quickstart
Run the command `:Pera<cr>` to open an interactive translation window and start
typing to see what happens! Type `g?` in normal mode or `i_CTRL-@` in insert
mode to open a help buffer with available keybindings. `Pera` also supports
ranges and optional flags for configuration of the translation process. Consult
the [documentation](doc/) for more details. If you plan to translate
frequently, the command can also be mapped to these recommended keybindings:

<details open><summary>Neovim 0.7+</summary>

```lua
local opts = {noremap = true, silent = true}
vim.keymap.set("n", "<leader>tr", perapera.motion_translate, opts)
vim.keymap.set("n", "<leader>trr", function() return perapera.motion_translate() .. "_" end, opts)
vim.keymap.set("x", "<leader>tr", perapera.motion_translate, opts)
```

</details>
<details><summary>Neovim 0.6</summary>

```lua
local opts = {noremap = true, silent = true}
vim.api.nvim_set_keymap("n", "<leader>tr", [[luaeval("require('perapera').motion_translate()")]], opts)
vim.api.nvim_set_keymap("n", "<leader>trr", [[luaeval("require('perapera').motion_translate() .. '_'")]], opts)
vim.api.nvim_set_keymap("x", "<leader>tr", [[luaeval("require('perapera').motion_translate()")]], opts)
```

</details>

Like the command above this allows you to use ranges, for example you can use
`3<leader>trr` to populate the translation window with the next three lines of
text. An advantage over the command, however, is the additional support for
[text objects](https://neovim.io/doc/user/motion.html#text-objects). You can
use `<leader>tris` or `<leader>trip` to translate the surrounding sentence or
paragraph, for example.

Other translation modes like replacing or appending text immediately without
opening an interactive window are also implemented. Again, consult the
[documentation](doc/) for more details.

## Supported Engines
The plugin already supports a few different translation engines. If
you have any further suggestions feel free to open an
[issue](https://github.com/potamides/perapera.nvim/issues) or [pull
request](https://github.com/potamides/perapera.nvim/pulls)! Currently supported
engines are as follows:

* [Apertium](https://apertium.org)
* [Argos Translate](https://translate.argosopentech.com),
* [DeepL](https://www.deepl.com/translator)
* [Google](https://translate.google.com/)
* [Yandex](https://translate.yandex.com/)

Some of these engines are free and open-source and can be used right off the
bat. However, some are commercial and might require additional setup steps. For
stability reasons, the philosophy of this plugin is to prioritize official API
end-points for which commercial engines usually require an auth key. When no
such key is configured and free alternative end-points exist then these are
used as a fallback. Note, however, that these are usually [severely
rate-limited](https://github.com/soimort/translate-shell/issues/370) and in some
instances produce [inferior
translations](https://github.com/Animenosekai/translate/issues/22). So if you
want use a commercial engine then creating an auth key is usually recommended
(see the [docs](doc/) for more information).

## Configuration
Perapera supports a wide range of configuration options. Some essential ones
are listed below, for a full list consult the additional [documentation](doc/).
The invocation of `require("perapera").setup()` is optional.
```lua
require("perapera").setup{
  engines = {
    -- Configuration for individual engines goes here. To list available engine
    -- identifiers run `:lua =vim.tbl_keys(require("perapera.engines"))`)
    default_engine = "argos"
    yandex = {
      -- Default languages can be defined on a per engine basis. In this case
      -- `:lua =require("perapera.async").run(function()
      -- vim.pretty_print(require("perapera.engines").yandex:languages()) end)`
      -- can be used to list available language identifiers.
      default_source = "auto",
      default_target = "en"
    },
  },
  controls = {
    mappings = {
      edit = {
        n = {
          -- Use the following config options to add additional mappings for
          -- the normal mode in the translation window. Either string or
          -- function references are supported.
          ["j"] = "gj",
          ["k"] = "gk"
        }
      }
    }
  }
}
```
