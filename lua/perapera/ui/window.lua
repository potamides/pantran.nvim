local events = require("perapera.ui.events")
local mappings = require("perapera.ui.mappings")
local async = require("perapera.async")
local config = require("perapera.config")
local utils = require("perapera.utils")

local window = {
  config = {
    width_percentage = 0.6,
    height_percentage = 0.3,
    min_height = 10,
    min_width = 40,
    title_border = {"┤ ", " ├"}, -- TODO: make the default without bars
    window_config = {
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
      winhighlight = "Normal:PeraperaNormal,FloatBorder:PeraperaBorder",
      textwidth = 0,
      spell=false -- FIXME: only do this in languagebar and title windows
    }
  },
  prop = {
    set = {},
    get = {}
  }
}

function window._gen_win_configs(title_width)
  local height = math.ceil(vim.o.lines * window.config.height_percentage)
  local width = math.floor(vim.o.columns * window.config.width_percentage)
  height, width = math.max(window.config.min_height, height), math.max(window.config.min_width, width)
  local row = math.floor(((vim.o.lines - height) / 2) - 1)
  local col = math.floor((vim.o.columns - width) / 2)

  local configs = {
    title = {
      focusable = false,
      border    = "none",
      row       = row,
      col       = col + math.ceil((width - (title_width or 1)) / 2) + 1,
      width     = title_width or 1,
      height    = 1,
    },
    languagebar = {
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
    configs[key] = vim.tbl_extend("force", window.config.window_config, conf)
  end

  return configs
end

function window._get_text(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr) and table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, true), "\n") or ""
end

function window._set_text(bufnr, text)
  -- check if window was closed already
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.split(text, "\n", {plain = true}))
  end
end

function window:_set_virtual(bufnr, args)
  local virt_text = vim.list_slice(args.virt_text or {})
  local sep = {" ", "PeraperaNormal"}
  if args.separate then
    for idx = #virt_text,0,-1 do
      if idx == #virt_text and args.right_align then
        table.insert(virt_text, idx + 1, sep)
      elseif idx == 0 and not args.right_align then
        table.insert(virt_text, idx + 1, sep)
      elseif idx >= 1 and idx < #virt_text then
        table.insert(virt_text, idx + 1, sep)
      end
    end
  end

  if vim.api.nvim_buf_is_valid(bufnr) then
    return vim.api.nvim_buf_set_extmark(bufnr, self._namespace, 0, 0, {
      id = args.id,
      virt_text_pos = args.right_align and "right_align" or "overlay",
      virt_text = virt_text
    })
  else
    return args.id
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
  local configs = window._gen_win_configs(vim.fn.strdisplaywidth(self._title))

  for win, conf in pairs(configs) do
    if vim.api.nvim_win_is_valid(self._win[win].win_id) then
        vim.api.nvim_win_set_config(self._win[win].win_id, conf)
    end
  end
end

function window:update()
  local title = {
    {self.config.title_border[1], "PeraperaBorder"},
    {self._engine.name, "PeraperaTitle"},
    {self.config.title_border[2], "PeraperaBorder"}
  }

  self._title_id = self:_set_virtual(self._win.title.bufnr, {
    id = self._title_id,
    virt_text = title
  })
  -- also set title as normal text so that window:resize resizes correctly
  self._title = table.concat(vim.tbl_map(function(v) return v[1] end, title))
  self:resize()

  -- clear source and target languages before updating asynchronously (which can take time)
  self._left_id = self:_set_virtual(self._win.languagebar.bufnr, {id = self._left_id})
  self._right_id = self:_set_virtual(self._win.languagebar.bufnr, {id = self._right_id})

  async.serial_run(window._update_languages, self)
end

function window:_update_languages()
  local langs = self._engine.languages()
  local source, target = langs.source[self._source], langs.target[self._target]
  local detected = self._detected and ("(%s)"):format(langs.source[self._detected])

  if source then
    self._left_id = self:_set_virtual(self._win.languagebar.bufnr, {
      id = self._left_id,
      virt_text = {{source, "PeraperaLanguagebar"}, detected and {detected, "PeraperaLanguagebar"} or nil},
      separate = true
    })
  end
  if target then
    self._right_id = self:_set_virtual(self._win.languagebar.bufnr, {
      id = self._right_id,
      virt_text = {{target, "PeraperaLanguagebar"}},
      separate = true,
      right_align = true
    })
  end
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

function window.prop.set:engine(engine)
  self._engine = engine
  self:update()
end

function window.prop.set:source(source)
  self._source = source
  self:update()
end

function window.prop.set:detected(detected)
  self._detected = detected
  self:update()
end

function window.prop.set:target(target)
  self._target = target
  self:update()
end

function window.prop.set:translation(translation)
  window._set_text(self._win.translation.bufnr, translation)
end

function window.prop.set:input(input)
  window._set_text(self._win.input.bufnr, input)
end

function window.prop.get:engine()
  return self._engine
end

function window.prop.get:source()
  return self._source
end

function window.prop.get:detected()
  return self._detected
end

function window.prop.get:target()
  return self._target
end

function window.prop.get:translation()
  return self._get_text(self._win.translation.bufnr)
end

function window.prop.get:input()
  return self._get_text(self._win.input.bufnr)
end

function window.new(engine, source, target)
  local configs, self = window._gen_win_configs()

  self = utils.make_properties(setmetatable({
      _engine = engine,
      _source = source or engine.config.default_source,
      _target = target or engine.config.default_target,
      _namespace = vim.api.nvim_create_namespace("perapera"),
      _win = {
        title = window._create_window(false, configs.title, window.config.options),
        languagebar = window._create_window(false, configs.languagebar, window.config.options),
        translation = window._create_window(false, configs.translation, window.config.options),
        input = window._create_window(true, configs.input, window.config.options),
      },
    }, {__index = window}))

  events.setup(self, self._win.input.bufnr)
  mappings.setup(self, self._win.input.bufnr)
  self:update()

  return self
end

return config.apply(config.user.window, window)
