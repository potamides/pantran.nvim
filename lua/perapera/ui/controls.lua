local actions = require("perapera.ui.actions")
local buffer = require("perapera.utils.buffer")
local zip = require("perapera.utils.table").zip
local config = require("perapera.config")

local controls = {}

controls.config = {
  updatetime = 300,
  mappings = {
    edit = {
      i = {
        ["<C-c>"] = actions.close,
        ["<C-_>"] = actions.help, -- keys from pressing <C-/>
        ["<C-y>"] = actions.yank_close_translation,
        ["<M-y>"] = actions.yank_close_input,
        ["<C-r>"] = actions.replace_close_translation,
        ["<M-r>"] = actions.replace_close_input,
        ["<C-a>"] = actions.append_close_translation,
        ["<M-a>"] = actions.append_close_input,
        ["<C-e>"] = actions.select_engine,
        ["<C-s>"] = actions.select_source,
        ["<C-t>"] = actions.select_target,
        ["<M-s>"] = actions.switch_languages,
        ["<M-t>"] = actions.translate
      },
      n = {
        ["q"] = actions.close,
        ["<Esc>"] = actions.close,
        ["g?"] = actions.help,
        ["gy"] = actions.yank_close_translation,
        ["gY"] = actions.yank_close_input,
        ["gr"] = actions.replace_close_translation,
        ["gR"] = actions.replace_close_input,
        ["ga"] = actions.append_close_translation,
        ["gA"] = actions.append_close_input,
        ["ge"] = actions.select_engine,
        ["gs"] = actions.select_source,
        ["gt"] = actions.select_target,
        ["gS"] = actions.switch_languages,
        ["gT"] = actions.translate
      }
    },
    select = {
      i = {
        ["<C-_>"] = actions.help, -- keys from pressing <C-/>
        ["<C-n>"] = actions.select_next,
        ["<C-p>"] = actions.select_prev,
        ["<C-j>"] = actions.select_next,
        ["<C-k>"] = actions.select_prev,
        ["<Down>"] = actions.select_next,
        ["<Up>"] = actions.select_prev,
        ["<Cr>"] = actions.select_choose,
        ["<C-y>"] = actions.select_choose,
        ["<C-e>"] = actions.select_abort
      },
      n = {
        ["j"] = actions.select_next,
        ["k"] = actions.select_prev,
        ["<Down>"] = actions.select_next,
        ["<Up>"] = actions.select_prev,
        ["g?"] = actions.help,
        ["gg"] = actions.select_first,
        ["G"] = actions.select_last,
        ["<Cr>"] = actions.select_choose,
        ["<Esc>"] = actions.select_abort,
        ["q"] = actions.select_abort
      }
    }
  }
}

function controls.create_events(ui, bufnr)
  local timer = vim.loop.new_timer()
  buffer.autocmd(bufnr, {
    events = {"TextChanged", "TextChangedI", "TextChangedP"},
    nested = true,
    callback = function()
      timer:start(controls.config.updatetime, 0, vim.schedule_wrap(function()
        actions.translate(ui)
      end))
  end
  })

  -- BufEnter
  actions.translate(ui)
end

function controls.setup(ui, edit_bufnr, select_bufnr)
  local mappings, opts = controls.config.mappings, {noremap = true, silent = true, nowait = true}
  for modes, bufnr in zip({mappings.edit, mappings.select}, {edit_bufnr, select_bufnr}) do
    for mode, maps in pairs(modes) do
      for lhs, rhs in pairs(maps) do
        if rhs then -- allow users to "unmap" binidngs with [<binding>] = false
          -- use name of actions as description, if applicable
          local description = type(rhs) == "string" and rhs or actions[rhs]
          buffer.keymap(bufnr, {
            mode = mode,
            lhs = lhs,
            rhs = type(rhs) == "string" and rhs or function() rhs(ui) end,
            desc = description,
            opts = opts
        })
      end
      end
    end
  end
  controls.create_events(ui, edit_bufnr)
end

return config.apply(config.user.controls, controls)
