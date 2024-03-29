# Usage
If not otherwise specified the remainder of this document assumes that
```lua
local pantran = require("pantran")
local actions = require("pantran.ui.actions")
local engines = require("pantran.engines")
local async = require("pantran.async")
```

#### pantran.setup({opts})
Setup function to be run by user.

Can be used to configure translation engines, appearance, and keybindings. The
invocation is optional, if you don't want to customize anything you don't need
to call it. Valid keys for `opt` are:

* `default_engine`: String which specifies the default engine to use in the
various translation modes. Can be one of `"apertium"`, `"argos"`, `"deepl"`,
`"google"`, and `"yandex"`. Default is `"argos"`.

* `command`: Table which can be used to configure the default behavior of
  [:Pantran](#rangepantran-args). It accepts the following keys:

  * `default_mode`: The default translation mode when it isn't explicitly
  specified on the command line. Accepted values are `"interactive"`, `"yank"`
  `"replace"` `"append"`, and `"hover"`. Default is `"interactive"`.

* `curl`: Table which configures the default behavior for invoking curl and
connecting to a server. Accepts the following keys:

  * `cmd`: The command used to invoke curl. Defaults to `curl`.

  * `retry`: Retry attempts when curl fails to connect to a server. Defaults
  to `3`.

  * `timeout`: Maximum time in seonds that curl's connection is allowed to
  take. Defaults to `15`.

  * `user_args`: List of additional arguments passed to curl, for example to
    specify a proxy. Defaults to an empty table.

* `help`: Table which configures the appearance of the help pop up window.
  Accepts the following keys:

  `separator`: Separator between elements in the help buffer. Defaults to
  `" ► "`.

* `ui`: Table which configures the appearance of the interactive user
interface. It accepts the following keys:

  * `width_percentage`: The percentage of the terminal window width that the
  UI should occupy. Defaults to `0.6`.

  * `height_percentage`: The percentage of the terminal window height that the
  UI should occupy. Defaults to `0.3`.

  * `min_height`: Minimum height of the UI in terminal rows. This is only used
  when the height calculated with `height_percentage` is smaller. Defaults to
  `10`.

  * `min_width`: Minimum width of the UI in terminal columns. This is only
  used when the width calculated with `width_percentage` is smaller.
  Defaults to `40`.

  * `scrollbind`: Configures if the translation window should scroll with the
  input window or not. Defaults to `true`.

* `select`: Table which configures the selection mode, i.e., when selecting
another language or engine. It accepts the following keys:

  * `prompt_prefix`: Prefix string used right before the input field for
  filtering matches. Defaults to `"> "`.

  * `selection_caret`: Prefix string used before the currently selected
  element in the selection window. Defaults to `"► "`.

* `window`: Table with configuration options for individual floating windows
of the user interface. It accepts the following keys:

  * `title_border`: Table with two elements that are used to decorate left and
  right sides of the window title. Defaults to `{"┤ ", " ├"}`.

  * `window_config`: Map the default window configuration. Consult the
  documentation of
  [nvim\_open\_win()](https://neovim.io/doc/user/api.html#nvim_open_win()) for
  a list of valid keys. Defaults to `{relative = "editor", border =
  "single"}`.

  * `options`: Table of options to set in each buffer and window. You can
  specify both buffer-local and window-local options. Defaults to
  ```lua
  {
    number         = false,
    relativenumber = false,
    cursorline     = false,
    cursorcolumn   = false,
    linebreak      = true,
    breakindent    = true,
    wrap           = true,
    foldcolumn     = "0",
    signcolumn     = "auto",
    colorcolumn    = "",
    fillchars      = "eob: ",
    winhighlight   = "Normal:PantranNormal,SignColumn:PantranNormal,FloatBorder:PantranBorder",
    textwidth      = 0
  }
  ```

* `engines`: Table with configuration options for individual engines. It
accepts the following keys:

  * `apertium`: See [Apertium](#apertium).

  * `argos`: See [Argos Translate](#argos-translate).

  * `deepl`: See [DeepL](#deepl).

  * `google`: See [Google Translate](#google-translate).

  * `yandex`: See [Yandex Translate](#yandex-translate).

* `controls`: Table with keybindings and other configuration options that are
directly influenced by them. Accepts the following keys:

  * `updatetime`: Milliseconds to wait for user input. If the user doesn't
  type anything in the specified time frame then the current input text is
  translated automatically and displayed in the translation window. Defaults
  to `300`.

  * `mappings`: Table for configuration of keybindings. This is a nested table
  structure. It can contain the keys `edit` and `select` which configure the
  keybindings used in the main translation window and during the selection
  mode. Each of these two tables can contain the keys `i` and `n` for
  setting insert and normal mode bindings. The key should be the actual
  binding and the value the action to perform. This can either be a
  function, a string, or `false` to disable an existing keybinding. Visit
  [default mappings](#default-mappings) for additional information.

#### :[range]Pantran {args}
Command for running a translation.

It supports various arguments which are expected to be in the `<key>=<value>`
format. Tab completion is also implemented. When a range is used then the
corresponding text is used to initialize the input in the translation window.
The following parameters are supported:

* `mode`: The translation mode to use instead of the default mode. Consult for
[pantran.setup()](#pantransetupopts) for a list of possible values.

* `engine`: The initial engine to use instead of the default engine. Consult
for [pantran.setup()](#pantransetupopts) for a list of possible values.

* `source`: The initial source language to use for this translation.
Allowed values depend on the engine, see [Engines](#engines) for details.

* `target`: The initial target language to use for this translation.
Allowed values depend on the engine, see [Engines](#engines) for details.

#### pantran.motion\_translate({opts})
Function to use in keybindings for translations.

This function is useful for keyboard mappings, as it supports both ranges and
motions. Which is helpful to quickly translate a piece of text. `opts` is a
table which supports the same keys and values as
[:Pantran](#rangepantran-args).

#### pantran.range\_translate({opts})
The function used internally by the command [:Pantran](#rangepantran-args).

The previous function [pantran.motion\_translate()](#pantranmotion_translate)
is probably the best choice for mappings, as this function does not support
motions. But in some cases this might be more useful (e.g., when for your own
custom commands). The allowed arguments are the same.

# Engines
Information about supported translation engines and their configuration.
Engines which are not properly configured (e.g., missing API keys) are
disabled automatically and can't be used. If there are fallback modes
available which do not require authentication then these are used instead.
Also note, that most engines split their input on newlines before attempting
translation. If you do not want that it is advisable to put all coherent input
text on one line. You could then use
[gj](https://neovim.io/doc/user/motion.html#gj) and
[gk](https://neovim.io/doc/user/motion.html#gk) to move over wrapped lines.
Default languages are configured on a per-engine basis and valid identifiers
might vary from engine to engine. You can list valid identifiers with the
following command (this examples uses `argos`):
```viml
:lua async.run(function() print(vim.inspect(engines.argos:languages())) end)
```
Other available configuration options usually reflect what the API endpoints
have to offer and are therefore different from engine to engine.

## Apertium
Apertium is a FOSS rule-based machine translation system and can be used
right away. For [pantran.setup()](#pantransetupopts) it supports the following
configuration keys:

* `default_source`: Primary source language to use for translation. Default
value is `"auto"`.

* `default_target`: Primary target language to use for translation. Default
value is `"eng"`.

* `fallback_source`: Apertium is a little bit quirky and sometimes the
language detection endpoint returns wrong languages that it also can't
translate. In these cases this language is used as a fallback. Default is
`"deu"`.

* `url`: URL of the Apertium instance to use. Defaults to
`"https://beta.apertium.org/apy"`.

* `markUnknown`: If `"yes"`, uses `*` to mark unknown words. Default value is
`"no"`.

* `format`: Text format of the translation input. Can be one of `"html"`,
`"txt"`, and `"rtf"`. Default value is `"txt"`.

## Argos Translate
Argos Translate is an open-source (offline) machine translation library. The
web-app and API built on top of it is called LibreTranslate. For
[pantran.setup()](#pantransetupopts) it supports the following configuration
keys:

* `default_source`: Primary source language to use for translation. Default
value is `"auto"`.

* `default_target`: Primary target language to use for translation. Default
value is `"en"`.

* `url`: URL of the Argos Translate instance to use. Defaults to
`"https://translate.terraprint.co"`.

* `api_key`: Some Argos Translate instances require an API key to control
traffic. The configured default instance does not, so you don't need to set
it. If you change the instance, however, you might also need to configure an
API key. Defaults to `vim.NIL`.

## DeepL
DeepL is a commercial and proprietary neural machine translation service. For
programmatic access, the DeepL API requires an API key. Without it this engine
can't be used and it is therefore deactivated. Note that a free API plan is
available. For [pantran.setup()](#pantransetupopts) it supports the following
configuration keys:

* `default_source`: Primary source language to use for translation. Default
value is `vim.NIL` (i.e., when unset the API will attempt to detect the
language automatically).

* `default_target`: Primary target language to use for translation. Default
value is `"EN-US"`.

* `auth_key`: The API key to use for this engine. Defaults to
`vim.env.DEEPL_AUTH_KEY` (i.e., an environment variable).

* `free_api`: Boolean which specifies whether the API key is for the DeepL API
Free or DeepL API Pro plan. Defaults to `true`.

* `split_sentences`: Sets whether the translation engine should first split
the input into sentences. Possible values are `0`, `1` (default), and
`nonewlines`.

* `preserve_formatting`: Sets whether the translation engine should respect
the original formatting, even if it would usually correct some aspects.
Possible values are `0` (default), and `1`.

* `formality`: Sets whether the translated text should lean towards formal or
informal language. Possible values are `"default"` (default), `"more"`, and
`"less"`.

## Google Translate
Google Translate is a machine translation service deployed by Google. The
implemented default endpoint uses the Google Translate v2/Basic API, for which
you need to authenticate with a Bearer token or API key for your account. If
this is not set up, this plugin falls back to unofficial endpoints used
internally by the web front-ends for Google Translate. Since these endpoints
are not supported by Google and are also rate-limited, setting up
authentication is recommended. For [pantran.setup()](#pantransetupopts) the
primary endpoint supports the following configuration keys:

* `default_source`: Primary source language to use for translation. Default
value is `vim.NIL` (i.e., when unset the API will attempt to detect the
language automatically).

* `default_target`: Primary target language to use for translation. Default
value is `"en"`.

* `bearer_token`: The token to use for this engine. Defaults to
`vim.env.GOOGLE_BEARER_TOKEN` (i.e., an environment variable).

* `api_key`: It is also possible to create an API key for authentication.
  Since API keys do not expire (unlike Bearer tokens) this authentication method
  is simpler. This has precedence over `bearer_token`. Defaults to
  `vim.env.GOOGLE_API_KEY` (i.e., an environment variable).

* `format`: Format of the text. Possible values are `"text"` (default)
and `"html"`.

* `fallback`: Table with configuration options for the fallback endpoint. It
  accepts the following keys:

  * `default_source`: Primary source language to use for translation. Default
  value is `"auto"`.

  * `default_target`: Primary target language to use for translation. Default
  value is `"en"`.

## Yandex Translate
Yandex Translate is a web service provided by Yandex for machine translation.
The default endpoint uses the Yandex Translate v2 API, for which you need to
authenticate with an IAM token or API key for your account. If you do not have
an account this plugin falls back to the old Yandex Translate v1 API which
works without authentication. Note, however that this endpoint is deprecated
and thus might stop working any time. For [pantran.setup()](#pantransetupopts)
the primary v2 endpoint supports the following configuration keys:

* `default_source`: Primary source language to use for translation. Default
value is `vim.NIL` (i.e., when unset the API will attempt to detect the
language automatically).

* `default_target`: Primary target language to use for translation. Default
value is `"en"`.

* `iam_token`: The token to use for this engine. Defaults to
`vim.env.YANDEX_IAM_TOKEN` (i.e., an environment variable).

* `api_key`: Service accounts can also use an API key for authentication.
  Since API keys do not expire (unlike IAM tokens) this authentication method
  is simpler. This has precedence over `iam_token`. Defaults to
  `vim.env.YANDEX_API_KEY` (i.e., an environment variable).

* `folder_id`: A folder is an isolated space where Yandex Cloud resources are
created and grouped. Setting this is only required for user accounts.
Defaults to `vim.env.YANDEX_FOLDER_ID` (i.e., an environment variable).

* `format`: Format of the text. Possible values are `"PLAIN_TEXT"` (default)
and `"HTML"`.

* `fallback`: Table with configuration options for the fallback v1 endpoint.
It accepts the following keys:

  * `default_source`: Primary source language to use for translation. Default
  value is `"auto"`.

  * `default_target`: Primary target language to use for translation. Default
  value is `"en"`.

# Default Mappings
Default keybindings for various modes in the interactive translation UI. If
not otherwise specified actions live in the `actions` module. Replace actions
replace the text with which the translation window was initialized (e.g.,
through a range or a movement). Note that `<C-_>` is the key from pressing
`<C-/>`.

## Edit Window

|Insert |Action                     |Description                             |
|:------|:--------------------------|:---------------------------------------|
|`<C-c>`|close                      |Terminate current translation.          |
|`<C-_>`|help                       |Show mappings in floating window.       |
|`<C-y>`|yank\_close\_translation   |Yank translation and quit.              |
|`<M-y>`|yank\_close\_input         |Yank input and quit.                    |
|`<C-r>`|replace\_close\_translation|Replace text with translation and quit. |
|`<M-r>`|replace\_close\_input      |Replace text with input and quit.       |
|`<C-a>`|append\_close\_translation |Append translation to text and quit.    |
|`<M-a>`|append\_close\_input       |Append input to text and quit.          |
|`<C-e>`|select\_engine             |Select a new translation engine.        |
|`<C-s>`|select\_source             |Select a new source language.           |
|`<C-t>`|select\_target             |Select a new target language.           |
|`<M-s>`|switch\_languages          |Switch source with target language.     |
|`<M-t>`|translate                  |Manually trigger translation.           |

|Normal |Action                     |Description                             |
|:------|:--------------------------|:---------------------------------------|
|`q`    |close                      |Terminate current translation.          |
|`<Esc>`|close                      |Terminate current translation.          |
|`g?`   |help                       |Show mappings in floating window.       |
|`gy`   |yank\_close\_translation   |Yank translation and quit.              |
|`gY`   |yank\_close\_input         |Yank input and quit.                    |
|`gr`   |replace\_close\_translation|Replace text with translation and quit. |
|`gR`   |replace\_close\_input      |Replace text with input and quit.       |
|`ga`   |append\_close\_translation |Append translation to text and quit.    |
|`gA`   |append\_close\_input       |Append input to text and quit.          |
|`ge`   |select\_engine             |Select a new translation engine.        |
|`gs`   |select\_source             |Select a new source language.           |
|`gt`   |select\_target             |Select a new target language.           |
|`gS`   |switch\_languages          |Switch source with target language.     |
|`gT`   |translate                  |Manually trigger translation.           |

## Select Mode

|Insert  |Action        |Description                                         |
|:-------|:-------------|:---------------------------------------------------|
|`<C-_>` |help          |Show mappings in floating window.                   |
|`<C-n>` |select\_next  |Select next item in the list.                       |
|`<C-p>` |select\_prev  |Select previous item in the list.                   |
|`<C-j>` |select\_next  |Select next item in the list.                       |
|`<C-k>` |select\_prev  |Select previous item in the list.                   |
|`<Down>`|select\_next  |Select next item in the list.                       |
|`<Up>`  |select\_prev  |Select previous item in the list.                   |
|`<Cr>`  |select\_choose|Choose current item and exit selection mode.        |
|`<C-y>` |select\_choose|Choose current item and exit selection mode.        |
|`<C-e>` |select\_abort |Abort current selection.                            |

|Normal  |Action        |Description                                         |
|:-------|:-------------|:---------------------------------------------------|
|`g?`    |help          |Show mappings in floating window.                   |
|`j`     |select\_next  |Select next item in the list.                       |
|`k`     |select\_prev  |Select previous item in the list.                   |
|`<Down>`|select\_next  |Select next item in the list.                       |
|`<Up>`  |select\_prev  |Select previous item in the list.                   |
|`gg`    |select\_first |Select first item in the list.                      |
|`G`     |select\_last  |Select last item in the list.                       |
|`<Cr>`  |select\_choose|Choose current item and exit selection mode.        |
|`<Esc>` |select\_abort |Abort current selection.                            |
|`q`     |select\_abort |Abort current selection.                            |

# Highlight Groups
Pantran.nvim defines and uses some highlight groups to bring color to its UI.
Advanced users can overwrite them to their liking. Run `:echo
getcompletion('Pantran', 'highlight')` to see which highlight groups are used.

# Programmatical Usage
Pantran.nvim can also be used as an API in your own scripts. Note, however,
that this is highly experimental as it requires access to internal APIs which
are subject to change.
```lua
local function translate(sentence)
  -- Engine methods can throw errors (e.g., due to timeouts or other network
  -- errors), which is why we use pcall.
  local ok, translation = pcall(engines.argos.translate, sentence)
  if ok then
    print(translation.text)
  end
end

async.run(translate, "Hallo Welt!") -- prints "Hello World!"
```

<!-- vim: set textwidth=78: -->
