local events = require("perapera.ui.events")
local mappings = require("perapera.ui.mappings")
local window = require("perapera.ui.window")
local async = require("perapera.async")
local config = require("perapera.config")
local properties = require("perapera.utils.properties")

local ui = {
  config = {
    width_percentage = 0.6,
    height_percentage = 0.3,
    min_height = 10,
    min_width = 40,
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
end

function ui:resize()
  local coords = ui._compute_win_coords()
  for name, win in pairs(self._win) do
    win:set_config(coords[name])
  end
end

function ui:update()
  self._win.languagebar:set_title(self._engine.name)

  -- clear source and target languages before updating asynchronously (which can take time)
  self._left_id = self._win.languagebar:set_virtual{id = self._left_id}
  self._right_id = self._win.languagebar:set_virtual{id = self._right_id}

  async.serial_run(ui._update_languages, self)
end

function ui:_update_languages()
  local langs = self._engine.languages()
  local source, target = langs.source[self._source], langs.target[self._target]
  local detected = self._detected and ("(%s)"):format(langs.source[self._detected])

  if source then
    self._left_id = self._win.languagebar:set_virtual{
      id = self._left_id,
      virt_text = {{source, "PeraperaLanguagebar"}, detected and {detected, "PeraperaLanguagebar"} or nil},
      separator = " "
    }
  end
  if target then
    self._right_id = self._win.languagebar:set_virtual{
      id = self._right_id,
      virt_text = {{target, "PeraperaLanguagebar"}},
      separator = " ",
      right_align = true
    }
  end
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
  self._detected = detected
  self:update()
end

function ui.prop.set:target(target)
  self._target = target
  self:update()
end

function ui.prop.set:translation(translation)
  self._win.translation:set_text(translation)
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

function ui.new(engine, source, target)
  local coords = ui._compute_win_coords()

  local self = properties.make(setmetatable({
      _engine = engine,
      _source = source or engine.config.default_source,
      _target = target or engine.config.default_target,
      _win = {
        languagebar = window.new(coords.languagebar),
        translation = window.new(coords.translation),
        input = window.new(coords.input)
      },
    }, {__index = ui}))

  self._win.input:enter()
  events.setup(self, self._win.input.bufnr)
  mappings.setup(self, self._win.input.bufnr)
  self:update()

  return self
end

return config.apply(config.user.ui, ui)
