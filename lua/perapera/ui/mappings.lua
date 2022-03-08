local actions = require("perapera.ui.actions")
local utils = require("perapera.utils")

local mappings = {}

mappings.mappings = {
  i = {
    ["<C-c>"] = actions.close,
    ["<C-_>"] = actions.help, -- keys from pressing <C-/>
    ["<C-y>"] = actions.yank_close_translation,
    ["<M-y>"] = actions.yank_close_input,
    ["<C-r>"] = actions.replace_close_translation,
    ["<M-r>"] = actions.replace_close_input,
    ["<C-a>"] = actions.append_close_translation,
    ["<M-a>"] = actions.append_close_input,
    ["<C-e>"] = actions.set_engine,
    ["<C-s>"] = actions.set_source,
    ["<C-t>"] = actions.set_target,
    ["<M-s>"] = actions.switch_languages,
    ["<M-t>"] = actions.translate
  },
  n = {
    ["<Esc>"] = actions.close,
    ["g?"] = actions.help,
    ["gy"] = actions.yank_close_translation,
    ["gY"] = actions.yank_close_input,
    ["gr"] = actions.replace_close_translation,
    ["gR"] = actions.replace_close_input,
    ["ga"] = actions.append_close_translation,
    ["gA"] = actions.append_close_input,
    ["ge"] = actions.set_engine,
    ["gs"] = actions.set_source,
    ["gt"] = actions.set_target,
    ["gS"] = actions.switch_languages,
    ["gT"] = actions.translate
  }
}

function mappings.setup(window)
  local buf, opts, state = window.input.bufnr, {noremap = true, silent = true}, {}
  for mode, maps in pairs(mappings.mappings) do
    for lhs, rhs in pairs(maps) do
      utils.buf_keymap(buf, {mode = mode, lhs = lhs, rhs = function() rhs(window, state) end, opts = opts})
    end
  end

end

return mappings
