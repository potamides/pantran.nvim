local controls = require("pantran.ui.controls")
local window = require("pantran.ui.window")
local selector = require("pantran.ui.select")
local async = require("pantran.async")
local config = require("pantran.config")
local properties = require("pantran.utils.properties")
local bufutils = require("pantran.utils.buffer")

local ui = {
  config = {
    width_percentage = 0.6,
    height_percentage = 0.3,
    min_height = 10,
    min_width = 40,
    scrollbind = true
  },
  prop = {
    set = {},
    get = {}
  }
}

function ui._compute_win_coords()
  local height = math.ceil(vim.o.lines * ui.config.height_percentage)
  local width = math.floor(vim.o.columns * ui.config.width_percentage)
  height, width = math.max(ui.config.min_height, height), math.max(ui.config.min_width, width)
  local row = math.floor(((vim.o.lines - height) / 2) - 1)
  local col = math.floor((vim.o.columns - width) / 2)

  local coords = {
    languagebar = {
      row       = row,
      col       = col,
      width     = width,
      height    = 1,
    },
    translation = {
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

  return coords
end

function ui:close()
  for _, win in pairs(self._win) do
    win:close()
  end
  pcall(vim.api.nvim_set_current_win, self._origin_win)
end

function ui:resize()
  local coords = ui._compute_win_coords()
  for name, win in pairs(self._win) do
    win:set_config(coords[name])
  end
end

function ui:update()
  self._win.languagebar:set_title(self._engine.name)

  async.run(function()
    self:lock()
    local langs = self._engine.languages()
    local source, target = langs.source[self._source], langs.target[self._target]
    local detected = self._detected and ("(%s)"):format(langs.source[self._detected])

    if source then
      self._win.languagebar:set_virtual{
        left = {{{source, "PantranLanguagebar"}, detected and {detected, "PantranLanguagebar"} or nil}},
        separator = " ",
        margin = " "
      }
    end
    if target then
      self._win.languagebar:set_virtual{
        right = {{{target, "PantranLanguagebar"}}},
        margin = " ",
      }
    end
    self:unlock()
  end)
end

function ui:select_left(items, opts, on_choice)
  self.select:set_item_win(self._win.input)
  self.select(items, opts, function(...)
    self._win.input:enter(true)
    self._win.input:clear_virtual()
    self._win.languagebar:clear_virtual()
    on_choice(...)
    self:update()
  end)
end

function ui:select_right(items, opts, on_choice)
  self.select:set_item_win(self._win.translation)
  self.select(items, opts, function(...)
    self._win.input:enter(true)
    self._win.translation:clear_virtual()
    self._win.languagebar:clear_virtual()
    on_choice(...)
    self:update()
  end)
end

function ui:lock()
  self._mutex:lock()
end

function ui:unlock()
  self._mutex:unlock()
end

function ui.prop.set:engine(engine)
  self._engine = engine
  self:update()
end

function ui.prop.set:source(source)
  self._source = source
  self:update()
end

function ui.prop.set:detected(detected)
  local input = self._win.input:get_text()
  self._detected = #input > 0 and detected or nil
  self:update()
end

function ui.prop.set:target(target)
  self._target = target
  self:update()
end

function ui.prop.set:translation(translation)
  local input = self._win.input:get_text()
  self._win.translation:set_text(#input > 0 and translation or nil)
end

function ui.prop.set:input(input)
  self._win.input:set_text(input)
end

function ui.prop.get:engine()
  return self._engine
end

function ui.prop.get:source()
  return self._source
end

function ui.prop.get:detected()
  return self._detected
end

function ui.prop.get:target()
  return self._target
end

function ui.prop.get:translation()
  return self._win.translation:get_text()
end

function ui.prop.get:input()
  return self._win.input:get_text()
end

function ui.new(engine, source, target, coords, text)
  local win_coords = ui._compute_win_coords()

  local self = properties.make(setmetatable({
      _engine = engine,
      _source = source or engine.config.default_source,
      _target = target or engine.config.default_target,
      _mutex = async.mutex.new(),
      _win = {
        languagebar = window.new(win_coords.languagebar),
        translation = window.new(win_coords.translation),
        input = window.new(win_coords.input)
      },
      _origin_win = vim.api.nvim_get_current_win(),
      coords = coords,
      previous = {} -- store for previous input, source, target, etc.
    }, {__index = ui}))

  self._win.input:set_option("scrollbind", self.config.scrollbind)
  self._win.translation:set_option("scrollbind", self.config.scrollbind)
  self.select = selector.new(self._win.languagebar, self._win.input)
  self._win.input:set_text(text)
  self._win.input:enter()
  controls.setup(self, self._win.input.bufnr, self._win.languagebar.virtnr)
  self:update()

  for _, buf in ipairs{self._win.input.bufnr, self._win.languagebar.virtnr} do
    bufutils.autocmd(buf, {
      events = "VimResized",
      nested = true,
      callback = function() self:resize() end
    })
    bufutils.autocmd(buf, {
      events = "WinLeave",
      nested = true,
      once = true,
      callback = function() self:close() end
    })
  end

  return self
end

return config.apply(config.user.ui, ui)
