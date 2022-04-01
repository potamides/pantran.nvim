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
  yank_close(window, window.translation)
end

function actions.yank_close_input(window)
  yank_close(window, window.input)
end

function actions.replace_close_translation(window)
  replace_close(window, window.translation)
end

function actions.replace_close_input(window)
  replace_close(window, window.input)
end

function actions.append_close_translation(window)
  append_close(window, window.translation)
end

function actions.append_close_input(window)
  append_close(window, window.input)
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
      window[prop] = lang
      actions.translate(window)
    end
  end
end

-- TODO: implement a more integrated picker for these kind of functions
actions.set_source = async.wrap(function(window)
  window:lock()
  local langs = window.engine.languages().source
  vim.ui.select(vim.tbl_keys(langs), {format_item = function(l) return langs[l] end}, on_lang(window, "source"))
  window:unlock()
end)

actions.set_target = async.wrap(function(window)
  window:lock()
  local langs = window.engine.languages().target
  vim.ui.select(vim.tbl_keys(langs), {format_item = function(l) return langs[l] end}, on_lang(window, "target"))
  window:unlock()
end)

actions.set_engine = async.wrap(function(window)
  local function on_choice(name)
    if name then
      window:lock()
      local engine = engines[name]
      window.engine = engine
      window.source = engine.config.default_source
      window.target = engine.config.default_target
      window.detected = nil
      actions.translate(window)
      window:unlock()
    end
  end
  vim.ui.select(vim.tbl_keys(engines), nil, on_choice)
end)

actions.switch_languages = async.wrap(function(window, state)
  window:lock()
  local source, target, detected, new_src, new_tgt = window.source, window.target, window.detected
  if not detected and state.previous and state.previous.source[source] and state.previous.target[target] then
    new_src, new_tgt = state.previous.source[source], state.previous.target[target]
  else
    new_src, new_tgt = window.engine.switch(detected or source, target)
  end

  if new_src ~= (detected or source) or window.target ~= target then
    window.input = window.translation
    window.source = new_src
    window.target = new_tgt
    window.detected = nil
    actions.translate(window)
  end

  state.previous = {
    -- put source and target in different tables for the edge case that they are the same
    source = {[window.source] = source},
    target = {[window.target] = target}
  }
  window:unlock()
end)

actions.translate = async.wrap(function(window)
  window:lock()
  local input, source, target = window.input, window.source, window.target
  local translated = #input > 0 and window.engine.translate(input, source, target) or {}

  window.translation = translated.text
  window.detected = translated.detected
  window:unlock()
end)

return actions
