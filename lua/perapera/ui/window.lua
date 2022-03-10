local events = require("perapera.ui.events")
local mappings = require("perapera.ui.mappings")
local async = require("perapera.async")
local config = require("perapera.config")

local window = {
  config = {
    width_percentage = 0.6,
    height_percentage = 0.3,
    min_height = 10,
    min_width = 40,
    win = {
      --style = 'minimal',
      relative = "editor",
      border = "single"
    },
    options = {
      number = false,
      relativenumber = false,
      cursorline = false,
      cursorcolumn = false,
      foldcolumn = "0",
      signcolumn = "auto",
      colorcolumn = "",
      fillchars = "eob: ",
      winhighlight = "Normal:Normal,FloatBorder:Normal",
      textwidth = 0
      -- TODO: spell off only in status window
    }
  }
}

function window._gen_win_configs()
  local height = math.ceil(vim.o.lines * window.config.height_percentage)
  local width = math.floor(vim.o.columns * window.config.width_percentage)
  height, width = math.max(window.config.min_height, height), math.max(window.config.min_width, width)
  local row = math.floor(((vim.o.lines - height) / 2) - 1)
  local col = math.floor((vim.o.columns - width) / 2)

  local configs = {
    status = {
      focusable = false,
      row       = row,
      col       = col,
      width     = width,
      height    = 1,
    },
    translation = {
      focusable = false,
      row       = row + 3,
      col       = col + math.ceil(width / 2) + 1,
      width     = math.floor(width / 2) - 1,
      height    = height - 3,
    },
    input = {
      row    = row + 3,
      col    = col,
      width  = math.ceil(width / 2) - 1,
      height = height - 3
    }
  }
  for key, conf in pairs(configs) do
    configs[key] = vim.tbl_extend("force", window.config.win, conf)
  end

  return configs
end

function window.get_text(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr) and table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, true), "\n") or ""
end

function window.set_text(bufnr, text)
  -- check if window was closed already
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.split(text, "\n", {plain = true}))
  end
end

function window:close()
  for _, win in pairs(self._win) do
    if vim.api.nvim_buf_is_valid(win.bufnr) then
      vim.api.nvim_buf_delete(win.bufnr, {})
    end
  end
end

function window:resize()
  local configs = window._gen_win_configs()

  for win, config in pairs(configs) do
    if vim.api.nvim_win_is_valid(self[win].win_id) then
        vim.api.nvim_win_set_config(self[win].win_id, config)
    end
  end
end

-- TODO: add detect
function window:update()
  async.run(function()
    local langs = self._engine.languages()
    local source, target = langs.source[self._source], langs.target[self._target]
    local detected = self._detected and langs.source[self._detected]

    if detected then
      window.set_text(self._win.status.bufnr, ("%s: %s (%s) -> %s"):format(self._engine.name, source, detected, target))
    else
      window.set_text(self._win.status.bufnr, ("%s: %s -> %s"):format(self._engine.name, source, target))
    end
  end)
end

function window._create_window(enter, conf, options)
  local bufnr = vim.api.nvim_create_buf(false, true)
  local win_id = vim.api.nvim_open_win(bufnr, enter, conf or {})
  vim.api.nvim_win_set_buf(win_id, bufnr)

  for option, value in pairs(options or {}) do
    -- FIXME: This is rather crude and could be solved with ftplugins
    pcall(vim.api.nvim_win_set_option, win_id, option, value)
    pcall(vim.api.nvim_buf_set_option, bufnr, option, value)
  end

  return {
    bufnr = bufnr,
    win_id = win_id
  }
end

function window:_get_prop(_, key)
  return self["_" .. key] or (self._win[key] and self.get_text(self._win[key].bufnr) or nil)
end

function window:_set_prop(_, key, value)
  if self._win[key] then
    window.set_text(self._win[key].bufnr, value)
  else
    self["_" .. key] = value
    self:update()
  end
end

function window.new(engine, source, target)
  local configs, self = window._gen_win_configs()

  self = setmetatable({
      _engine = engine,
      _source = source or engine.config.default_source,
      _target = target or engine.config.default_target,
      _win = {
        status = window._create_window(false, configs.status, window.config.options),
        translation = window._create_window(false, configs.translation, window.config.options),
        input = window._create_window(true, configs.input, window.config.options),
      },
      prop = setmetatable({}, {
        __newindex = function(...) self:_set_prop(...) end,
        __index = function(...) return self:_get_prop(...) end
      })
    }, {__index = window})

  events.setup(self, self._win.input.bufnr)
  mappings.setup(self, self._win.input.bufnr)
  self:update()

  return self
end

return config.apply(config.user.window, window)
