local utils = require("perapera.utils")
local events = require("perapera.ui.events")
local mappings = require("perapera.ui.mappings")

local window = {
  width_percentage = 0.6,
  height_percentage = 0.3,
  min_height = 10,
  min_width = 40,
  config = {
    --style = 'minimal',
    relative = "editor",
    border = "single"
  },
  -- TODO: make ftplugin for this
  options = {
    number = false,
    relativenumber = false,
    cursorline = false,
    cursorcolumn = false,
    foldcolumn = "0",
    signcolumn = "auto",
    colorcolumn = "",
    fillchars = "eob: ",
    winhighlight = "Normal:Normal,FloatBorder:Normal"
    --textwidth = 0 # TODO
  }
}

function window.gen_win_configs()
  local height = math.ceil(vim.o.lines * window.height_percentage)
  local width = math.floor(vim.o.columns * window.width_percentage)
  height, width = math.max(window.min_height, height), math.max(window.min_width, width)
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
  for key, config in pairs(configs) do
    configs[key] = vim.tbl_extend("force", window.config, config)
  end

  return configs
end

function window.get_text(bufnr)
  return table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, true), "\n")
end

function window.set_text(bufnr, text)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.split(text, "\n", {plain = true}))
end

function window:get_input()
  return window.get_text(self.input.bufnr)
end

function window:set_input(text)
  window.set_text(self.input.bufnr, text)
end

function window:get_status()
  return window.get_text(self.status.bufnr)
end

function window:set_status(text)
  window.set_text(self.status.bufnr, text)
end

function window:get_translation()
  return window.get_text(self.translation.bufnr)
end

function window:set_translation(text)
  window.set_text(self.translation.bufnr, text)
end

function window:close()
  for _, win in pairs{self.input, self.status, self.translation} do
    if vim.api.nvim_buf_is_valid(win.bufnr) then
      vim.api.nvim_buf_delete(win.bufnr, {})
    end
  end
end

function window:resize()
  local configs = window.gen_win_configs()

  for win, config in pairs(configs) do
    if vim.api.nvim_win_is_valid(self[win].win_id) then
        vim.api.nvim_win_set_config(self[win].win_id, config)
    end
  end
end

function window.create_window(enter, config, options)
  local bufnr = vim.api.nvim_create_buf(false, true)
  local win_id = vim.api.nvim_open_win(bufnr, enter, config or {})
  vim.api.nvim_win_set_buf(win_id, bufnr)

  for option, value in pairs(options or {}) do
    vim.api.nvim_win_set_option(win_id, option, value)
  end

  return {
    bufnr = bufnr,
    win_id = win_id
  }
end

function window.new(engine, source, target)
  local configs = window.gen_win_configs()

  local self = setmetatable({
      engine = engine,
      source = source,
      target = target,
      status = window.create_window(false, configs.status, window.options),
      translation = window.create_window(false, configs.translation, window.options),
      input = window.create_window(true, configs.input, window.options)
    }, {__index = window})

  events.setup(self)
  mappings.setup(self)

  return self
end

return window
