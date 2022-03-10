local async = require("perapera.async")
local engines = require("perapera.engines")
local actions = {}

function actions.help()
  error("Not implemented!") -- TODO
end

local function yank_close(window, text)
  local reg = ({[""] = '"', unnamed = "*", unnamedplus = "+"})[vim.o.clipboard]
  vim.fn.setreg(reg, text, "u")
  window:close()
end

local function replace_close(window, text)
  window:close()
  if window.coords then
    error("Not implemented!") -- TODO
  else
    vim.api.nvim_paste(text, false, -1)
  end
end

local function append_close(window, text)
  window:close()
  if window.coords then
    error("Not implemented!") -- TODO
  else
    vim.api.nvim_paste(text, false, -1)
  end
end

function actions.yank_close_translation(window)
  yank_close(window, window.prop.translation)
end

function actions.yank_close_input(window)
  yank_close(window, window.prop.input)
end

function actions.replace_close_translation(window)
  replace_close(window, window.prop.translation)
end

function actions.replace_close_input(window)
  replace_close(window, window.prop.input)
end

function actions.append_close_translation(window)
  append_close(window, window.prop.translation)
end

function actions.append_close_input(window)
  append_close(window, window.prop.input)
end

function actions.close(window)
  window:close()
end

function actions.resize(window)
  window:resize()
end

local function on_lang(window, prop)
  return function(lang)
    if lang then
      window.prop[prop] = lang
      actions.translate(window)
    end
  end
end

-- TODO: implement a more integrated picker for these kind of functions
actions.set_source = async.wrap(function(window)
  local langs  = window.prop.engine.languages().source
  vim.ui.select(vim.tbl_keys(langs), {format_item = function(l) return langs[l] end}, on_lang(window, "source"))
end)

actions.set_target = async.wrap(function(window)
  local langs  = window.prop.engine.languages().target
  vim.ui.select(vim.tbl_keys(langs), {format_item = function(l) return langs[l] end}, on_lang(window, "target"))
end)

actions.set_engine = async.wrap(function(window)
  local function on_choice(name)
    if name then
      local engine = engines[name]
      window.prop.engine = engine
      window.prop.source = engine.config.default_source
      window.prop.target = engine.config.default_target
      actions.translate(window)
    end
  end
  vim.ui.select(vim.tbl_keys(engines), nil, on_choice)
end)

actions.switch_languages = async.wrap(function(window, state)
  local p = window.prop
  local source, target, detected = p.source, p.target, p.detected

  if state.previous and state.previous[p.source] and state.previous[p.target] then
    p.source, p.target = state.previous[p.source], state.previous[p.target]
  else
    p.source, p.target = p.engine.switch(detected or source, target)
  end

  if p.source ~= source and p.target ~= target then
    p.detected = nil
    p.input = p.translation
    actions.translate(window)
  end

  state.previous = {
    [p.source] = source,
    [p.target] = target,
  }
end)

actions.translate = async.wrap(function(window)
  local input, source, target = window.prop.input, window.prop.source, window.prop.target
  local translation = #input > 0 and window.prop.engine.translate(input, source, target) or {}
  window.prop.translation = translation.text or ""
  window.prop.detected = translation.detected
end)

return actions
